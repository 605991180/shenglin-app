import 'package:sqflite/sqflite.dart';
import '../models/tag.dart';
import 'database_helper.dart';

class TagDao {
  static Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  static Future<int> insert(Tag tag) async {
    final db = await _db;
    return await db.insert('tags', tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  static Future<List<Tag>> getAll() async {
    final db = await _db;
    final maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  static Future<Tag?> getByName(String name) async {
    final db = await _db;
    final maps =
        await db.query('tags', where: 'name = ?', whereArgs: [name], limit: 1);
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  static Future<int> update(Tag tag) async {
    final db = await _db;
    return await db
        .update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  static Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteMultiple(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('tags',
        where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// Returns a map of tagId -> spirit count
  static Future<Map<int, int>> getTagSpiritCounts() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT tag_id, COUNT(spirit_id) as count
      FROM spirit_tags
      GROUP BY tag_id
    ''');
    final map = <int, int>{};
    for (final row in results) {
      map[row['tag_id'] as int] = row['count'] as int;
    }
    return map;
  }

  static Future<List<Tag>> search(String query) async {
    final db = await _db;
    final maps = await db.query('tags',
        where: 'name LIKE ?', whereArgs: ['%$query%'], orderBy: 'name ASC');
    return maps.map((m) => Tag.fromMap(m)).toList();
  }
}
