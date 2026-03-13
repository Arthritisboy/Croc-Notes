import 'dart:io';
import 'package:archive/archive.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/data/services/image_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackupService {
  final DatabaseService db = DatabaseService();
  final ImageStorageService _imageStorage = ImageStorageService();

  Future<String?> exportBackup() async {
    try {
      final appDir = await db.getAppDataDirectory();
      final dbPath = path.join(appDir, 'croc_notes.db');

      // Create archive
      final archive = Archive();

      // Add database file
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(
          ArchiveFile('database/croc_notes.db', dbBytes.length, dbBytes),
        );
      }

      // Get all images with their relative paths
      final images = await _imageStorage.getAllImagesForExport();

      for (final entry in images.entries) {
        final bytes = await entry.value.readAsBytes();
        archive.addFile(
          ArchiveFile('images/${entry.key}', bytes.length, bytes),
        );
      }

      // Write ZIP file
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('Failed to create archive');

      // Save to Downloads
      final downloadsDir = Directory(
        Platform.isWindows
            ? '${Platform.environment['USERPROFILE']}\\Downloads'
            : '/storage/emulated/0/Download',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        path.join(downloadsDir.path, 'croc_notes_backup_$timestamp.zip'),
      );

      await backupFile.writeAsBytes(zipData);
      return backupFile.path;
    } catch (e) {
      print('Export failed: $e');
      return null;
    }
  }

  Future<bool> importBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await db.getAppDataDirectory();

      // Extract database
      final dbFile = archive.findFile('database/croc_notes.db');
      if (dbFile != null) {
        final dbPath = path.join(appDir, 'croc_notes.db');
        await File(dbPath).writeAsBytes(dbFile.content as List<int>);
      }

      // Extract images using ImageStorageService
      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final fileName = path.basename(file.name);

          // Create a temp file with the image data
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File(path.join(tempDir.path, fileName));
          await tempFile.writeAsBytes(file.content as List<int>);

          // Import using storage service (this handles the correct location)
          await _imageStorage.importImage(tempFile, fileName);

          // Clean up temp
          await tempFile.delete();
          await tempDir.delete();
        }
      }

      return true;
    } catch (e) {
      print('Import failed: $e');
      return false;
    }
  }
}
