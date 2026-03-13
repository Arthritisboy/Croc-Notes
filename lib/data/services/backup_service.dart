// lib/core/services/backup_service.dart
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackupService {
  final DatabaseService db = DatabaseService();

  // Get the app data directory (where the database and images are stored)
  Future<String> getAppDataDirectory() async {
    return db.getAppDataDirectory();
  }

  // Export all data to a single backup file
  Future<String?> exportBackup() async {
    try {
      // Get directories from app data folder
      final appDir = await getAppDataDirectory();
      final dbPath = path.join(appDir, 'croc_notes.db');
      final imagesDir = path.join(appDir, 'images');

      debugPrint('Backing up from: $appDir');

      // Create archive
      final archive = Archive();

      // Add database file
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(
          ArchiveFile('database/croc_notes.db', dbBytes.length, dbBytes),
        );
        debugPrint('Added database file to backup');
      } else {
        debugPrint('Database file not found at: $dbPath');
      }

      // Add all images
      final imagesDirectory = Directory(imagesDir);
      if (await imagesDirectory.exists()) {
        int imageCount = 0;
        await for (final file in imagesDirectory.list()) {
          if (file is File) {
            final bytes = await file.readAsBytes();
            final fileName = path.basename(file.path);
            archive.addFile(
              ArchiveFile('images/$fileName', bytes.length, bytes),
            );
            imageCount++;
          }
        }
        debugPrint('Added $imageCount images to backup');
      }

      // Write ZIP file
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('Failed to create archive');

      // Save to Downloads folder (user accessible)
      String downloadsPath;
      if (Platform.isWindows) {
        downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      } else {
        final downloadsDir = await getDownloadsDirectory();
        downloadsPath =
            downloadsDir?.path ??
            (await getApplicationDocumentsDirectory()).path;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'croc_notes_backup_$timestamp.zip';
      final backupFile = File(path.join(downloadsPath, backupFileName));

      await backupFile.writeAsBytes(zipData);
      debugPrint('Backup saved to: ${backupFile.path}');

      return backupFile.path;
    } catch (e) {
      debugPrint('Export failed: $e');
      return null;
    }
  }

  // Import from backup file
  Future<bool> importBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await getAppDataDirectory();
      debugPrint('Importing to: $appDir');

      // Extract database
      final dbFile = archive.findFile('database/croc_notes.db');
      if (dbFile != null) {
        final dbPath = path.join(appDir, 'croc_notes.db');
        await File(dbPath).writeAsBytes(dbFile.content as List<int>);
        debugPrint('Restored database file');
      } else {
        debugPrint('No database file found in backup');
      }

      // Extract images
      final imagesDir = Directory(path.join(appDir, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      int imageCount = 0;
      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final fileName = path.basename(file.name);
          final imagePath = path.join(imagesDir.path, fileName);
          await File(imagePath).writeAsBytes(file.content as List<int>);
          imageCount++;
        }
      }
      debugPrint('Restored $imageCount images');

      return true;
    } catch (e) {
      debugPrint('Import failed: $e');
      return false;
    }
  }

  // Optional: Get backup file size
  Future<int?> getBackupFileSize(String zipPath) async {
    try {
      final file = File(zipPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting backup file size: $e');
      return null;
    }
  }
}
