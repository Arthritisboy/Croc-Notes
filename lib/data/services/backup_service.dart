import 'dart:io';
import 'package:archive/archive.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackupService {
  final DatabaseService db = DatabaseService();

  // Export all data to a single backup file
  Future<String?> exportBackup() async {
    try {
      // Get directories
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'journal_app.db');
      final imagesDir = path.join(documentsDir.path, 'journal_images');

      // Create archive
      final archive = Archive();

      // Add database file
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(
          ArchiveFile('database/journal_app.db', dbBytes.length, dbBytes),
        );
      }

      // Add all images
      final imagesDirectory = Directory(imagesDir);
      if (await imagesDirectory.exists()) {
        await for (final file in imagesDirectory.list()) {
          if (file is File) {
            final bytes = await file.readAsBytes();
            final fileName = path.basename(file.path);
            archive.addFile(
              ArchiveFile('images/$fileName', bytes.length, bytes),
            );
          }
        }
      }

      // Write ZIP file
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('Failed to create archive');

      // Save to Downloads folder (user accessible)
      final downloadsDir = Directory('/storage/emulated/0/Download'); // Android
      if (Platform.isWindows) {
        final windowsDownloads = Directory(
          '${Platform.environment['USERPROFILE']}\\Downloads',
        );
        final backupFile = File(
          path.join(
            windowsDownloads.path,
            'journal_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
          ),
        );
        await backupFile.writeAsBytes(zipData);
        return backupFile.path;
      } else {
        final backupFile = File(
          path.join(
            downloadsDir.path,
            'journal_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
          ),
        );
        await backupFile.writeAsBytes(zipData);
        return backupFile.path;
      }
    } catch (e) {
      print('Export failed: $e');
      return null;
    }
  }

  // Import from backup file
  Future<bool> importBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentsDir = await getApplicationDocumentsDirectory();

      // Extract database
      final dbFile = archive.findFile('database/journal_app.db');
      if (dbFile != null) {
        final dbPath = path.join(documentsDir.path, 'journal_app.db');
        await File(dbPath).writeAsBytes(dbFile.content as List<int>);
      }

      // Extract images
      final imagesDir = Directory(
        path.join(documentsDir.path, 'journal_images'),
      );
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }

      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final fileName = path.basename(file.name);
          final imagePath = path.join(imagesDir.path, fileName);
          await File(imagePath).writeAsBytes(file.content as List<int>);
        }
      }

      return true;
    } catch (e) {
      print('Import failed: $e');
      return false;
    }
  }
}
