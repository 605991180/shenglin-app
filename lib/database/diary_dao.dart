import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import 'database_helper.dart';

class DiaryDao {
  static const _uuid = Uuid();

  static Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  static String generateId() {
    return _uuid.v4();
  }

  // ==================== 日记 CRUD ====================

  static Future<void> insert(DiaryEntry entry) async {
    final db = await _db;
    await db.insert('diaries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> update(DiaryEntry entry) async {
    final db = await _db;
    await db.update('diaries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  static Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<DiaryEntry?> getById(String id) async {
    final db = await _db;
    final maps =
        await db.query('diaries', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  static Future<List<DiaryEntry>> getAll() async {
    final db = await _db;
    final maps = await db.query('diaries', orderBy: 'date DESC');
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  static Future<List<DiaryEntry>> getByDateRange(
      DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'diaries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  static Future<List<DiaryEntry>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return getByDateRange(start, end);
  }

  static Future<List<DiaryEntry>> search(String query) async {
    final db = await _db;
    final likeQuery = '%$query%';
    final maps = await db.query(
      'diaries',
      where: 'content LIKE ? OR location LIKE ?',
      whereArgs: [likeQuery, likeQuery],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  static Future<int> getCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM diaries');
    return result.first['count'] as int;
  }

  static Future<int> getCountByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM diaries WHERE date >= ? AND date <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return result.first['count'] as int;
  }

  /// 获取某月中有日记的日期列表（用于日历标点）
  static Future<Set<int>> getDatesWithEntries(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final db = await _db;
    final maps = await db.query(
      'diaries',
      columns: ['date'],
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );
    final days = <int>{};
    for (final map in maps) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      days.add(dt.day);
    }
    return days;
  }

  static Future<void> toggleBookmark(String id, bool isBookmarked) async {
    final db = await _db;
    await db.update(
      'diaries',
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 草稿 ====================

  static Future<void> saveDraft(DiaryDraft draft) async {
    final db = await _db;
    await db.insert('diary_drafts', draft.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<DiaryDraft?> getDraft([String? diaryId]) async {
    final db = await _db;
    List<Map<String, dynamic>> maps;
    if (diaryId != null) {
      maps = await db.query('diary_drafts',
          where: 'diary_id = ?', whereArgs: [diaryId], limit: 1);
    } else {
      maps = await db.query('diary_drafts',
          where: 'diary_id IS NULL',
          orderBy: 'saved_at DESC',
          limit: 1);
    }
    if (maps.isEmpty) return null;
    return DiaryDraft.fromMap(maps.first);
  }

  static Future<void> deleteDraft(String id) async {
    final db = await _db;
    await db.delete('diary_drafts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllDrafts() async {
    final db = await _db;
    await db.delete('diary_drafts');
  }

  // ==================== 导出 ====================

  static Future<List<DiaryEntry>> getEntriesForExport({
    DateTime? start,
    DateTime? end,
  }) async {
    if (start != null && end != null) {
      return getByDateRange(start, end);
    }
    return getAll();
  }
}
