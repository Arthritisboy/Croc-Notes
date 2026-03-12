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

    // IMPORTANT: Increment version to 2 to trigger onUpgrade
    return await openDatabase(
      dbPath,
      version: 2, // Changed from 1 to 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add this for migrations
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
        colorValue INTEGER DEFAULT 0, -- ADD THIS COLUMN
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

  // Add this method for database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add colorValue column to tabs table
      try {
        await db.execute(
          'ALTER TABLE tabs ADD COLUMN colorValue INTEGER DEFAULT 0',
        );
        print('Successfully added colorValue column to tabs table');
      } catch (e) {
        print('Error adding colorValue column: $e');
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
