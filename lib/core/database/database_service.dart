import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Get the app data directory (where the executable is)
  Future<String> getAppDataDirectory() async {
    if (Platform.isWindows) {
      // Windows: Portable - next to executable
      final executablePath = Platform.resolvedExecutable;
      final appDir = path.dirname(executablePath);
      final dataDir = path.join(appDir, 'data');
      final dataDirectory = Directory(dataDir);

      if (!await dataDirectory.exists()) {
        await dataDirectory.create(recursive: true);
        debugPrint('📁 [Windows] Created data directory: $dataDir');
      }

      return dataDir;
    } else if (Platform.isMacOS) {
      // macOS: Use Application Support directory
      final appSupportDir = await getApplicationSupportDirectory();
      final appDir = path.join(appSupportDir.path, 'CrocNotes');
      final appDirectory = Directory(appDir);

      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
        debugPrint('📁 [macOS] Created app directory: $appDir');
      }

      return appDir;
    } else {
      // Android/iOS: App-specific storage
      final documentsDir = await getApplicationDocumentsDirectory();
      final appDir = path.join(documentsDir.path, 'CrocNotes');
      final appDirectory = Directory(appDir);

      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
        debugPrint('📁 [Mobile] Created app directory: $appDir');
      }

      return appDir;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appDir = await getAppDataDirectory();
    final dbPath = path.join(appDir, 'croc_notes.db');

    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    debugPrint('📁 Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        isExpanded INTEGER DEFAULT 1,
        sortOrder INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE tabs(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        isPinned INTEGER DEFAULT 0,
        colorValue INTEGER DEFAULT 0,
        notepadContent TEXT,
        contentNotepad TEXT,
        sortOrder INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items(
        id TEXT PRIMARY KEY,
        tabId TEXT NOT NULL,
        title TEXT NOT NULL,
        checkboxState INTEGER DEFAULT 0,
        timerState INTEGER DEFAULT 0,
        timerEndTime TEXT,
        timerDuration INTEGER,
        alarmSoundPath TEXT,
        isLoopingAlarm INTEGER DEFAULT 0,
        timerStartTime TEXT,
        elapsedTime INTEGER,
        sortOrder INTEGER,
        FOREIGN KEY (tabId) REFERENCES tabs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE images(
        id TEXT PRIMARY KEY,
        tabId TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileSize INTEGER,
        sortOrder INTEGER,
        FOREIGN KEY (tabId) REFERENCES tabs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE tabs ADD COLUMN colorValue INTEGER DEFAULT 0',
        );
        debugPrint('Added colorValue column to tabs table');
      } catch (e) {
        debugPrint('Error adding colorValue column: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        final tableInfo = await db.rawQuery(
          'PRAGMA table_info(checklist_items)',
        );
        final existingColumns = tableInfo
            .map((col) => col['name'] as String)
            .toList();

        if (!existingColumns.contains('timerState')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerState INTEGER DEFAULT 0',
          );
        }
        if (!existingColumns.contains('timerEndTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerEndTime TEXT',
          );
        }
        if (!existingColumns.contains('timerDuration')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerDuration INTEGER',
          );
        }
        if (!existingColumns.contains('alarmSoundPath')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN alarmSoundPath TEXT',
          );
        }
        if (!existingColumns.contains('isLoopingAlarm')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN isLoopingAlarm INTEGER DEFAULT 0',
          );
        }
        if (!existingColumns.contains('timerStartTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerStartTime TEXT',
          );
        }
        if (!existingColumns.contains('elapsedTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN elapsedTime INTEGER',
          );
        }

        debugPrint(
          'Successfully added all timer columns to checklist_items table',
        );
      } catch (e) {
        debugPrint('Error adding timer columns: $e');
      }
    }

    // VERSION 4 MIGRATION - Fix images table schema
    if (oldVersion < 4) {
      try {
        debugPrint('Starting version 4 migration for images table...');

        // Check if images table exists
        final tableInfo = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='images'",
        );
        final imagesTableExists = tableInfo.isNotEmpty;

        if (imagesTableExists) {
          // Get current images table schema
          final columns = await db.rawQuery('PRAGMA table_info(images)');
          final columnNames = columns
              .map((col) => col['name'] as String)
              .toList();

          debugPrint('Current images table columns: $columnNames');

          // Check if filePath column exists
          final hasFilePath = columnNames.contains('filePath');

          if (hasFilePath) {
            debugPrint('Migrating images table from version 3 to 4...');

            // Create a temporary table with the new schema
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

            // Copy data from old table, extracting filename from filePath
            // This handles both absolute paths and just filenames
            await db.execute('''
            INSERT INTO images_new (id, tabId, fileName, fileSize, sortOrder)
            SELECT 
              id, 
              tabId,
              CASE 
                WHEN filePath LIKE '%\\%' THEN substr(filePath, lastindexof(filePath, '\\') + 1)
                WHEN filePath LIKE '%/%' THEN substr(filePath, lastindexof(filePath, '/') + 1)
                ELSE filePath
              END as fileName,
              COALESCE(fileSize, 0),
              sortOrder
            FROM images
          ''');

            // Get count of migrated images
            final countResult = await db.rawQuery(
              'SELECT COUNT(*) as count FROM images_new',
            );
            final imageCount = countResult.first['count'] as int;
            debugPrint('Migrated $imageCount images to new schema');

            // Drop old table
            await db.execute('DROP TABLE images');

            // Rename new table to images
            await db.execute('ALTER TABLE images_new RENAME TO images');

            debugPrint('✅ Successfully migrated images table to version 4');
          } else {
            debugPrint(
              'Images table already has version 4 schema (no filePath column)',
            );
          }
        } else {
          debugPrint('Images table does not exist, skipping migration');
        }
      } catch (e) {
        debugPrint('❌ Error migrating images table: $e');

        // If migration fails, try to recreate the table
        try {
          debugPrint('Attempting to recreate images table...');
          await db.execute('DROP TABLE IF EXISTS images');
          await db.execute('''
          CREATE TABLE images(
            id TEXT PRIMARY KEY,
            tabId TEXT NOT NULL,
            fileName TEXT NOT NULL,
            fileSize INTEGER,
            sortOrder INTEGER,
            FOREIGN KEY (tabId) REFERENCES tabs (id) ON DELETE CASCADE
          )
        ''');
          debugPrint('✅ Recreated images table with version 4 schema');
        } catch (e2) {
          debugPrint('❌ Critical error: Could not recreate images table: $e2');
        }
      }
    }
  }

  // Updated to use app directory
  Future<String> getImagesDirectory() async {
    final dir = await getAppDataDirectory();
    final imagesDir = path.join(dir, 'images');
    await Directory(imagesDir).create(recursive: true);
    return imagesDir;
  }

  static String getImagesDirectorySync() {
    if (Platform.isWindows) {
      final executablePath = Platform.resolvedExecutable;
      final appDir = path.dirname(executablePath);
      return path.join(appDir, 'data', 'images');
    } else {
      // For other platforms, use async version
      return '';
    }
  }

  static Future<String> getImagesDirectoryAsync() async {
    if (Platform.isWindows) {
      return getImagesDirectorySync();
    } else if (Platform.isMacOS) {
      final appSupportDir = await getApplicationSupportDirectory();
      return path.join(appSupportDir.path, 'CrocNotes', 'images');
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      return path.join(documentsDir.path, 'CrocNotes', 'images');
    }
  }
}
