// lib/core/database/database_service.dart
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
      // For Windows, use the directory where the executable is located
      final executablePath = Platform.resolvedExecutable;
      final appDir = path.dirname(executablePath);

      // Create a 'data' subfolder to keep things organized
      final dataDir = path.join(appDir, 'data');
      final dataDirectory = Directory(dataDir);

      if (!await dataDirectory.exists()) {
        await dataDirectory.create(recursive: true);
        debugPrint('Created data directory: $dataDir');
      }

      return dataDir;
    } else {
      // For other platforms, fallback to app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final appDir = path.join(documentsDir.path, 'CrocNotes');
      final appDirectory = Directory(appDir);

      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
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
    final dbPath = path.join(appDir, 'croc_notes.db'); // Changed filename

    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    debugPrint('Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: 3,
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
        filePath TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileSize INTEGER,
        sortOrder INTEGER,
        FOREIGN KEY (tabId) REFERENCES tabs (id) ON DELETE CASCADE
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
  }

  // Updated to use app directory
  Future<String> getImagesDirectory() async {
    final appDir = await getAppDataDirectory();
    final imagesDir = Directory(path.join(appDir, 'images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
      debugPrint('Created images directory: ${imagesDir.path}');
    }

    return imagesDir.path;
  }
}
