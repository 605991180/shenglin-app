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
      version: 3,
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

    // 精养田表
    await db.execute('''
      CREATE TABLE refined_field (
        id TEXT PRIMARY KEY,
        person_id TEXT NOT NULL,
        name TEXT NOT NULL,
        position TEXT,
        coin_level INTEGER NOT NULL,
        department_id TEXT NOT NULL,
        department_name TEXT NOT NULL,
        sub_category_id TEXT NOT NULL,
        system_id TEXT NOT NULL,
        resources TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (person_id) REFERENCES spirits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_refined_field_dept ON refined_field(department_id)');
    await db.execute('CREATE INDEX idx_refined_field_system ON refined_field(system_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE spirits ADD COLUMN identity TEXT');
      await db.execute('ALTER TABLE spirits ADD COLUMN identity_level TEXT');
    }
    if (oldVersion < 3) {
      // 添加精养田表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS refined_field (
          id TEXT PRIMARY KEY,
          person_id TEXT NOT NULL,
          name TEXT NOT NULL,
          position TEXT,
          coin_level INTEGER NOT NULL,
          department_id TEXT NOT NULL,
          department_name TEXT NOT NULL,
          sub_category_id TEXT NOT NULL,
          system_id TEXT NOT NULL,
          resources TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (person_id) REFERENCES spirits(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_refined_field_dept ON refined_field(department_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_refined_field_system ON refined_field(system_id)');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
