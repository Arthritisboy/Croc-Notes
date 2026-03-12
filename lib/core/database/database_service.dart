import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'journal_app.db');

    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    return await openDatabase(
      dbPath,
      version: 3, // Increment to 3
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
    print('Upgrading database from version $oldVersion to $newVersion');

    // Upgrade to version 2 (add colorValue to tabs)
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE tabs ADD COLUMN colorValue INTEGER DEFAULT 0',
        );
        print('Added colorValue column to tabs table');
      } catch (e) {
        print('Error adding colorValue column: $e');
      }
    }

    // Upgrade to version 3 (add timer fields to checklist_items)
    if (oldVersion < 3) {
      try {
        // Check if columns already exist (optional, but safe)
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
          print('Added timerState column');
        }

        if (!existingColumns.contains('timerEndTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerEndTime TEXT',
          );
          print('Added timerEndTime column');
        }

        if (!existingColumns.contains('timerDuration')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerDuration INTEGER',
          );
          print('Added timerDuration column');
        }

        if (!existingColumns.contains('alarmSoundPath')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN alarmSoundPath TEXT',
          );
          print('Added alarmSoundPath column');
        }

        if (!existingColumns.contains('isLoopingAlarm')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN isLoopingAlarm INTEGER DEFAULT 0',
          );
          print('Added isLoopingAlarm column');
        }

        if (!existingColumns.contains('timerStartTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN timerStartTime TEXT',
          );
          print('Added timerStartTime column');
        }

        if (!existingColumns.contains('elapsedTime')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN elapsedTime INTEGER',
          );
          print('Added elapsedTime column');
        }

        print('Successfully added all timer columns to checklist_items table');
      } catch (e) {
        print('Error adding timer columns: $e');
      }
    }
  }

  Future<String> getImagesDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(documentsDir.path, 'journal_images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir.path;
  }
}
