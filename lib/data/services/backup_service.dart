import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/data/services/image_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

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
      debugPrint('Importing to: $appDir');

      // Extract database
      final dbFile = archive.findFile('database/croc_notes.db');
      if (dbFile != null) {
        final dbPath = path.join(appDir, 'croc_notes.db');
        await File(dbPath).writeAsBytes(dbFile.content as List<int>);
        debugPrint('✅ Restored database file');

        // Check if this is a version 3 database and migrate images
        await _migrateVersion3ImagesIfNeeded(dbPath);
      } else {
        debugPrint('❌ No database file found in backup');
      }

      // Extract images using ImageStorageService
      int imageCount = 0;
      int missingCount = 0;

      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final fileName = path.basename(file.name);

          try {
            // Create a temp file with the image data
            final tempDir = await Directory.systemTemp.createTemp();
            final tempFile = File(path.join(tempDir.path, fileName));
            await tempFile.writeAsBytes(file.content as List<int>);

            // Import using storage service
            await _imageStorage.importImage(tempFile, fileName);

            // Clean up temp
            await tempFile.delete();
            await tempDir.delete();

            imageCount++;
            debugPrint('  ✅ Imported image: $fileName');
          } catch (e) {
            missingCount++;
            debugPrint('  ❌ Failed to import image: $fileName - $e');
          }
        }
      }

      debugPrint('✅ Imported $imageCount images');
      if (missingCount > 0) {
        debugPrint('⚠️ Failed to import $missingCount images');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Import failed: $e');
      return false;
    }
  }

  Future<void> _migrateVersion3ImagesIfNeeded(String dbPath) async {
    try {
      // Open the database temporarily to check version and migrate images
      final db = await openDatabase(dbPath);

      // Check database version
      final version = await db.getVersion();
      debugPrint('Imported database version: $version');

      if (version < 4) {
        debugPrint('Migrating version $version database to version 4...');

        // Check if images table has filePath column
        final tableInfo = await db.rawQuery('PRAGMA table_info(images)');
        final columnNames = tableInfo
            .map((col) => col['name'] as String)
            .toList();

        if (columnNames.contains('filePath')) {
          debugPrint('Migrating images from filePath to fileName...');

          // Get all images with filePath
          final images = await db.query('images');

          for (final image in images) {
            final oldFilePath = image['filePath'] as String?;
            final imageId = image['id'] as String;
            final tabId = image['tabId'] as String;
            final sortOrder = image['sortOrder'] as int? ?? 0;

            // Extract filename from path
            String fileName = imageId; // Default to id

            if (oldFilePath != null && oldFilePath.isNotEmpty) {
              // Try to extract filename
              if (oldFilePath.contains('\\')) {
                fileName = oldFilePath.split('\\').last;
              } else if (oldFilePath.contains('/')) {
                fileName = oldFilePath.split('/').last;
              } else {
                fileName = oldFilePath;
              }

              // Try to find the actual image file
              final possiblePaths = [
                oldFilePath, // Original path
                path.join(
                  await _imageStorage.getImagesDirectory(),
                  fileName,
                ), // New location
              ];

              bool imageFound = false;
              for (final srcPath in possiblePaths) {
                final srcFile = File(srcPath);
                if (await srcFile.exists()) {
                  // Copy to new location
                  await _imageStorage.importImage(srcFile, fileName);
                  debugPrint('  ✅ Migrated image: $fileName');
                  imageFound = true;
                  break;
                }
              }

              if (!imageFound) {
                debugPrint('  ⚠️ Image file not found: $oldFilePath');
              }
            }

            // Update the database entry to use just fileName
            await db.update(
              'images',
              {'fileName': fileName},
              where: 'id = ?',
              whereArgs: [imageId],
            );
          }

          // Remove filePath column (SQLite doesn't support DROP COLUMN directly)
          // Instead, recreate the table
          await db.execute('''
          CREATE TABLE images_new(
            id TEXT PRIMARY KEY,
            tabId TEXT NOT NULL,
            fileName TEXT NOT NULL,
            fileSize INTEGER,
            sortOrder INTEGER,
            FOREIGN KEY (tabId) REFERENCES tabs (id) ON DELETE CASCADE
          )
        ''');

          await db.execute('''
          INSERT INTO images_new (id, tabId, fileName, fileSize, sortOrder)
          SELECT id, tabId, fileName, fileSize, sortOrder FROM images
        ''');

          await db.execute('DROP TABLE images');
          await db.execute('ALTER TABLE images_new RENAME TO images');

          debugPrint('✅ Removed filePath column from images table');
        }

        // Update database version
        await db.setVersion(4);
        debugPrint('✅ Database version updated to 4');
      }

      await db.close();
    } catch (e) {
      debugPrint('❌ Error during version migration: $e');
    }
  }
}
