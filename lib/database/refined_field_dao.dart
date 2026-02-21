import 'package:sqflite/sqflite.dart';
import '../models/refined_field_models.dart';
import 'database_helper.dart';

class RefinedFieldDao {
  static Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  /// 生成唯一ID
  static String generateId(String personId, String departmentId) {
    return '${personId}_$departmentId';
  }

  /// 插入精养人员
  static Future<void> insert(RefinedPerson person) async {
    final db = await _db;
    await db.insert('refined_field', person.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 更新精养人员
  static Future<void> update(RefinedPerson person) async {
    final db = await _db;
    await db.update('refined_field', person.toMap(),
        where: 'id = ?', whereArgs: [person.id]);
  }

  /// 删除精养人员
  static Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('refined_field', where: 'id = ?', whereArgs: [id]);
  }

  /// 根据ID获取
  static Future<RefinedPerson?> getById(String id) async {
    final db = await _db;
    final maps = await db.query('refined_field',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return RefinedPerson.fromMap(maps.first);
  }

  /// 获取所有精养人员
  static Future<List<RefinedPerson>> getAll() async {
    final db = await _db;
    final maps = await db.query('refined_field', orderBy: 'created_at DESC');
    return maps.map((m) => RefinedPerson.fromMap(m)).toList();
  }

  /// 根据部门ID获取人员
  static Future<List<RefinedPerson>> getByDepartmentId(String departmentId) async {
    final db = await _db;
    final maps = await db.query('refined_field',
        where: 'department_id = ?',
        whereArgs: [departmentId],
        orderBy: 'coin_level DESC');
    return maps.map((m) => RefinedPerson.fromMap(m)).toList();
  }

  /// 根据系统ID获取人员
  static Future<List<RefinedPerson>> getBySystemId(String systemId) async {
    final db = await _db;
    final maps = await db.query('refined_field',
        where: 'system_id = ?',
        whereArgs: [systemId],
        orderBy: 'coin_level DESC');
    return maps.map((m) => RefinedPerson.fromMap(m)).toList();
  }

  /// 检查人员是否已在精养田中
  static Future<bool> isPersonInField(String personId) async {
    final db = await _db;
    final result = await db.query('refined_field',
        where: 'person_id = ?', whereArgs: [personId], limit: 1);
    return result.isNotEmpty;
  }

  /// 获取部门人员数量
  static Future<int> getDepartmentPersonCount(String departmentId) async {
    final db = await _db;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM refined_field WHERE department_id = ?',
        [departmentId]);
    return result.first['count'] as int;
  }

  /// 获取精养田总人数
  static Future<int> getTotalCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM refined_field');
    return result.first['count'] as int;
  }
}
