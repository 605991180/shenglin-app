import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/spirit.dart';
import '../models/tag.dart';
import '../utils/pinyin_utils.dart';
import 'database_helper.dart';

class SpiritDao {
  static Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  static Future<String> generateId() async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final prefix = 'SL-$dateStr-';
    final db = await _db;
    final results = await db.query('spirits',
        columns: ['id'], where: 'id LIKE ?', whereArgs: ['$prefix%']);
    int maxSeq = 0;
    for (final row in results) {
      final id = row['id'] as String;
      final seqStr = id.split('-').last;
      final seq = int.tryParse(seqStr) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }
    final newSeq = (maxSeq + 1).toString().padLeft(2, '0');
    return '$prefix$newSeq';
  }

  static Future<void> insert(Spirit spirit) async {
    final db = await _db;
    await db.insert('spirits', spirit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (spirit.tags.isNotEmpty) {
      await updateSpiritTags(
          spirit.id, spirit.tags.map((t) => t.id!).toList());
    }
  }

  static Future<void> update(Spirit spirit) async {
    final db = await _db;
    await db.update('spirits', spirit.toMap(),
        where: 'id = ?', whereArgs: [spirit.id]);
  }

  static Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('spirits', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Spirit?> getById(String id) async {
    final db = await _db;
    final maps =
        await db.query('spirits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    final spirit = Spirit.fromMap(maps.first);
    spirit.tags = await getTagsForSpirit(id);
    return spirit;
  }

  static Future<List<Spirit>> getAll() async {
    final db = await _db;
    final maps = await db.query('spirits', orderBy: 'pinyin ASC');
    final spirits = maps.map((m) => Spirit.fromMap(m)).toList();
    for (final spirit in spirits) {
      spirit.tags = await getTagsForSpirit(spirit.id);
    }
    return spirits;
  }

  static Future<List<Tag>> getTagsForSpirit(String spiritId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN spirit_tags st ON t.id = st.tag_id
      WHERE st.spirit_id = ?
    ''', [spiritId]);
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  static Future<void> updateSpiritTags(
      String spiritId, List<int> tagIds) async {
    final db = await _db;
    await db
        .delete('spirit_tags', where: 'spirit_id = ?', whereArgs: [spiritId]);
    for (final tagId in tagIds) {
      await db.insert('spirit_tags', {
        'spirit_id': spiritId,
        'tag_id': tagId,
      });
    }
  }

  static Future<List<Spirit>> search(String query) async {
    final db = await _db;
    final likeQuery = '%$query%';
    // Search in name, preference, personality, affinity
    final maps = await db.query('spirits',
        where:
            'name LIKE ? OR preference LIKE ? OR personality LIKE ? OR affinity LIKE ?',
        whereArgs: [likeQuery, likeQuery, likeQuery, likeQuery],
        orderBy: 'pinyin ASC');
    final spirits = maps.map((m) => Spirit.fromMap(m)).toList();

    // Also search by tag name
    final tagResults = await db.rawQuery('''
      SELECT DISTINCT s.* FROM spirits s
      INNER JOIN spirit_tags st ON s.id = st.spirit_id
      INNER JOIN tags t ON st.tag_id = t.id
      WHERE t.name LIKE ?
      ORDER BY s.pinyin ASC
    ''', [likeQuery]);

    final tagSpirits = tagResults.map((m) => Spirit.fromMap(m)).toList();
    final existingIds = spirits.map((s) => s.id).toSet();
    for (final s in tagSpirits) {
      if (!existingIds.contains(s.id)) {
        spirits.add(s);
      }
    }

    for (final spirit in spirits) {
      spirit.tags = await getTagsForSpirit(spirit.id);
    }
    spirits.sort((a, b) => (a.pinyin ?? '').compareTo(b.pinyin ?? ''));
    return spirits;
  }

  static Future<int> getCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM spirits');
    return result.first['count'] as int;
  }

  static Spirit prepareSpirit(Spirit spirit) {
    final py = PinyinUtils.getPinyin(spirit.name);
    final fl = PinyinUtils.getFirstLetter(spirit.name);
    return spirit.copyWith(pinyin: py, firstLetter: fl);
  }
}
