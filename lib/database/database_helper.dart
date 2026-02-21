import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shenglin.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spirits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT,
        gender TEXT,
        age INTEGER,
        identity TEXT,
        identity_level TEXT,
        preference TEXT,
        personality TEXT,
        affinity TEXT,
        phone TEXT,
        memo TEXT,
        photos TEXT,
        type_labels TEXT,
        created_at INTEGER NOT NULL,
        pinyin TEXT,
        first_letter TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE spirit_tags (
        spirit_id TEXT NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (spirit_id, tag_id),
        FOREIGN KEY (spirit_id) REFERENCES spirits(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_spirits_first_letter ON spirits(first_letter)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE spirits ADD COLUMN identity TEXT');
      await db.execute('ALTER TABLE spirits ADD COLUMN identity_level TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
