import 'dart:convert';
import 'dart:io';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/spirit_dao.dart';
import '../database/refined_field_dao.dart';
import '../database/diary_dao.dart';
import '../models/refined_field_models.dart';
import '../models/diary_entry.dart';

class CsvExportHelper {
  // ==================== CSV 通用方法 ====================

  /// 将二维列表转为CSV字符串
  static String listToCsv(List<List<dynamic>> rows) {
    return rows.map((row) => row.map(_escapeCsvField).join(',')).join('\r\n');
  }

  /// CSV字段转义：含逗号、双引号、换行时用双引号包裹
  static String _escapeCsvField(dynamic field) {
    final str = field?.toString() ?? '';
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// 生成CSV文件并返回File对象
  static Future<File> exportToCSV({
    required String filePrefix,
    required List<String> headers,
    required List<List<dynamic>> dataRows,
  }) async {
    final csv = listToCsv([headers, ...dataRows]);

    final now = DateTime.now();
    final fileName = '${filePrefix}_'
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    // 写入BOM + UTF-8内容，确保Excel正确识别中文编码
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    return file;
  }

  // ==================== 生灵池 ====================

  static const spiritHeaders = [
    'ID', '姓名', '拼音', '首字母', '性别', '年龄', '民族', '身份证号',
    '身份', '身份层级', '首要关系', '电话', '偏好', '性格', '亲密度',
    '分类标签', '备忘', '照片数', '有头像', '创建时间',
  ];

  static Future<List<List<dynamic>>> buildSpiritRows() async {
    final spirits = await SpiritDao.getAll();
    return spirits
        .map((s) => [
              s.id,
              s.name,
              s.pinyin ?? '',
              s.firstLetter ?? '',
              s.gender ?? '',
              s.age != null ? s.age.toString() : '',
              s.ethnicity ?? '',
              s.idNumber ?? '',
              s.identity ?? '',
              s.identityLevel ?? '',
              s.primaryRelation ?? '',
              s.phone.join(';'),
              s.preference ?? '',
              s.personality ?? '',
              s.affinity ?? '',
              s.typeLabels.isNotEmpty
                  ? s.typeLabels.join(';')
                  : s.tags.map((t) => t.name).join(';'),
              s.memo ?? '',
              s.photos.length.toString(),
              (s.avatar != null && s.avatar!.isNotEmpty) ? '是' : '否',
              s.createdAt.toString().substring(0, 19),
            ])
        .toList();
  }

  // ==================== 精养田 ====================

  static const refinedFieldHeaders = [
    '系统', '小类', '部门', '姓名', '职务', '电话', '硬币等级', '可调用的资源',
  ];

  static Future<List<List<dynamic>>> buildRefinedFieldRows() async {
    final systems = OfficialSystemData.getSystems();
    final refinedPersons = await RefinedFieldDao.getAll();

    // 构建 personId -> phone 的映射
    final phoneMap = <String, String>{};
    for (final p in refinedPersons) {
      final spirit = await SpiritDao.getById(p.personId);
      if (spirit != null) {
        phoneMap[p.personId] = spirit.phone.join(';');
      }
    }

    // 将人员分配到对应部门
    for (final system in systems) {
      for (final sub in system.subCategories) {
        for (final dept in sub.departments) {
          dept.persons =
              refinedPersons.where((p) => p.departmentId == dept.id).toList();
        }
      }
    }

    // 按 系统→小类→部门→姓名 排序遍历
    final rows = <List<dynamic>>[];
    for (final system in systems) {
      for (final sub in system.subCategories) {
        for (final dept in sub.departments) {
          for (final person in dept.persons) {
            rows.add([
              system.name,
              sub.name,
              dept.name,
              person.name,
              person.position ?? '',
              phoneMap[person.personId] ?? '',
              _coinLevelToChinese(person.level),
              person.resources.join(';'),
            ]);
          }
        }
      }
    }
    return rows;
  }

  static String _coinLevelToChinese(CoinLevel level) {
    switch (level) {
      case CoinLevel.gold:
        return '金币';
      case CoinLevel.silver:
        return '银币';
      case CoinLevel.bronze:
        return '铜币';
      case CoinLevel.iron:
        return '铁币';
    }
  }

  // ==================== 日记 ====================

  static const diaryHeaders = [
    '日期', '时间', '星期', '天气', '地点', '内容', '字数',
  ];

  static Future<List<List<dynamic>>> buildDiaryRows() async {
    final entries = await DiaryDao.getAll(); // 已按日期倒序
    return entries
        .map((d) => [
              DateFormat('yyyy-MM-dd').format(d.date),
              DateFormat('HH:mm').format(d.date),
              _getWeekDay(d.date),
              d.weather ?? '',
              d.location ?? '',
              _extractPlainText(d),
              d.wordCount.toString(),
            ])
        .toList();
  }

  static String _getWeekDay(DateTime date) {
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekDays[date.weekday - 1];
  }

  /// 从Quill JSON中提取纯文本，去除图片和HTML标记
  static String _extractPlainText(DiaryEntry entry) {
    if (entry.content.isEmpty) return '';
    try {
      final doc = Document.fromJson(jsonDecode(entry.content));
      return doc.toPlainText().trim();
    } catch (_) {
      return entry.content
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\[image:[^\]]*\]'), '')
          .trim();
    }
  }
}
