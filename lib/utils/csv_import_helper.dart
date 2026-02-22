import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/spirit_dao.dart';
import '../database/refined_field_dao.dart';
import '../database/diary_dao.dart';
import '../models/spirit.dart';
import '../models/refined_field_models.dart';
import '../models/diary_entry.dart';
import '../widgets/import_result_dialog.dart';
import 'csv_parser.dart';

class CsvImportHelper {
  static const _uuid = Uuid();

  // ==================== 精养田导入 ====================

  /// 解析精养田CSV，返回数据行和缺失的人员名单
  static Future<({List<Map<String, String>> rows, List<String> missingNames})>
      parseRefinedFieldCsv(String csvText) async {
    final parsed = CsvParser.parse(csvText);
    final existingSpirits = await SpiritDao.getAll();
    final nameSet = existingSpirits.map((s) => s.name).toSet();

    final missingNames = <String>{};
    for (final row in parsed.rows) {
      final name = CsvParser.getValue(row, ['姓名', 'name', 'Name'], '');
      if (name.isNotEmpty && !nameSet.contains(name)) {
        missingNames.add(name);
      }
    }

    return (rows: parsed.rows, missingNames: missingNames.toList());
  }

  /// 为缺失人员创建生灵池记录
  static Future<void> createMissingSpirits(
    List<Map<String, String>> rows,
    List<String> missingNames,
  ) async {
    final missingSet = missingNames.toSet();

    for (final row in rows) {
      final name = CsvParser.getValue(row, ['姓名', 'name', 'Name'], '');
      if (!missingSet.contains(name)) continue;

      // 创建新的生灵记录
      final phoneStr = CsvParser.getValue(row, ['电话', 'phone', 'Phone'], '');
      final phones = CsvParser.parseListField(phoneStr);

      final spirit = Spirit(
        id: await SpiritDao.generateId(),
        name: name,
        phone: phones,
        identity: '政客', // 默认分类
        typeLabels: ['政客'],
      );

      await SpiritDao.insert(SpiritDao.prepareSpirit(spirit));
      missingSet.remove(name); // 避免重复创建
    }
  }

  /// 导入精养田数据（先清空再导入）
  static Future<ImportResult> importRefinedField(
    List<Map<String, String>> rows,
  ) async {
    int added = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    // 获取现有生灵用于关联
    final existingSpirits = await SpiritDao.getAll();
    final nameToSpirit = <String, Spirit>{};
    for (final s in existingSpirits) {
      nameToSpirit[s.name] = s;
    }

    // 获取系统数据
    final systems = OfficialSystemData.getSystems();

    // 构建系统/小类/部门映射
    final systemMap = <String, OfficialSystem>{};
    final subCategoryMap = <String, SubCategory>{};
    final departmentMap = <String, Department>{};

    for (final system in systems) {
      systemMap[system.name] = system;
      for (final sub in system.subCategories) {
        subCategoryMap[sub.name] = sub;
        for (final dept in sub.departments) {
          departmentMap[dept.name] = dept;
        }
      }
    }

    // 清空现有精养田数据
    final existingPersons = await RefinedFieldDao.getAll();
    for (final p in existingPersons) {
      await RefinedFieldDao.delete(p.id);
    }

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 2;

      try {
        final name = CsvParser.getValue(row, ['姓名', 'name', 'Name'], '');
        if (name.isEmpty) {
          skipped++;
          continue;
        }

        final spirit = nameToSpirit[name];
        if (spirit == null) {
          skipped++;
          errorMessages.add('第$rowNum行：$name 不在生灵池中，已跳过');
          continue;
        }

        // 获取组织结构信息
        final systemName = CsvParser.getValue(row, ['系统', 'system'], '');
        final subCategoryName = CsvParser.getValue(row, ['小类', 'subCategory', 'sub_category'], '');
        final deptName = CsvParser.getValue(row, ['部门', 'department'], '');

        if (deptName.isEmpty) {
          skipped++;
          errorMessages.add('第$rowNum行：$name 缺少部门信息，已跳过');
          continue;
        }

        // 查找部门
        final dept = departmentMap[deptName];
        if (dept == null) {
          skipped++;
          errorMessages.add('第$rowNum行：部门"$deptName"不存在，已跳过');
          continue;
        }

        // 查找小类和系统
        SubCategory? subCategory;
        OfficialSystem? system;

        if (subCategoryName.isNotEmpty) {
          subCategory = subCategoryMap[subCategoryName];
        }
        if (systemName.isNotEmpty) {
          system = systemMap[systemName];
        }

        // 如果没有指定，根据部门推断
        subCategory ??= systems
            .expand((s) => s.subCategories)
            .firstWhere(
              (sub) => sub.departments.any((d) => d.id == dept.id),
              orElse: () => systems.first.subCategories.first,
            );
        system ??= systems.firstWhere(
          (s) => s.subCategories.contains(subCategory),
          orElse: () => systems.first,
        );

        // 解析硬币等级
        final coinLevelStr = CsvParser.getValue(row, ['硬币等级', 'coinLevel', 'coin_level'], '');
        final coinLevel = _parseCoinLevel(coinLevelStr);

        // 解析职务
        final position = CsvParser.getValue(row, ['职务', 'position'], '');

        // 解析资源标签
        final resourcesStr = CsvParser.getValue(row, ['可调用的资源', 'resources'], '');
        final resources = CsvParser.parseListField(resourcesStr);

        // 创建精养人员
        final refinedPerson = RefinedPerson(
          id: RefinedFieldDao.generateId(spirit.id, dept.id),
          personId: spirit.id,
          name: name,
          position: position.isNotEmpty ? position : null,
          level: coinLevel,
          departmentId: dept.id,
          departmentName: dept.name,
          subCategoryId: subCategory.id,
          systemId: system.id,
          resources: resources,
        );

        await RefinedFieldDao.insert(refinedPerson);
        added++;
      } catch (e) {
        errors++;
        errorMessages.add('第$rowNum行：$e');
      }
    }

    return ImportResult(
      total: rows.length,
      added: added,
      updated: 0,
      skipped: skipped,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  /// 解析硬币等级
  static CoinLevel _parseCoinLevel(String value) {
    switch (value.trim()) {
      case '金币':
      case 'gold':
      case '正科级':
        return CoinLevel.gold;
      case '银币':
      case 'silver':
      case '副科级':
        return CoinLevel.silver;
      case '铜币':
      case 'bronze':
      case '股所级':
        return CoinLevel.bronze;
      case '铁币':
      case 'iron':
      case '科员':
      case '办事员':
      default:
        return CoinLevel.iron;
    }
  }

  // ==================== 日记导入 ====================

  /// 导入日记数据
  static Future<ImportResult> importDiaries(
    String csvText, {
    bool overwrite = false,
  }) async {
    final parsed = CsvParser.parse(csvText);
    if (parsed.rows.isEmpty) {
      return ImportResult(
        total: 0,
        added: 0,
        updated: 0,
        skipped: 0,
        errors: 0,
        errorMessages: ['CSV文件为空或格式错误'],
      );
    }

    int added = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    // 如果是覆盖模式，先清空现有日记
    if (overwrite) {
      final existingDiaries = await DiaryDao.getAll();
      for (final d in existingDiaries) {
        await DiaryDao.delete(d.id);
      }
    }

    // 获取现有日记用于去重
    final existingDiaries = await DiaryDao.getAll();
    final existingKeys = <String>{};
    for (final d in existingDiaries) {
      final key = _buildDiaryKey(d.date, _extractPlainTextFromContent(d.content));
      existingKeys.add(key);
    }

    for (var i = 0; i < parsed.rows.length; i++) {
      final row = parsed.rows[i];
      final rowNum = i + 2;

      try {
        // 解析日期时间
        final dateStr = CsvParser.getValue(row, ['日期', 'date', 'Date'], '');
        final timeStr = CsvParser.getValue(row, ['时间', 'time', 'Time'], '');

        if (dateStr.isEmpty) {
          skipped++;
          errorMessages.add('第$rowNum行：缺少日期，已跳过');
          continue;
        }

        final date = _parseDateTime(dateStr, timeStr);
        if (date == null) {
          skipped++;
          errorMessages.add('第$rowNum行：日期格式错误，已跳过');
          continue;
        }

        // 获取内容
        final content = CsvParser.getValue(row, ['内容', 'content', 'Content'], '');
        if (content.isEmpty) {
          skipped++;
          continue;
        }

        // 去重检查：日期+时间+内容
        final key = _buildDiaryKey(date, content);
        if (existingKeys.contains(key)) {
          skipped++;
          continue;
        }

        // 获取其他字段
        final weather = CsvParser.getValue(row, ['天气', 'weather', 'Weather'], '');
        final location = CsvParser.getValue(row, ['地点', 'location', 'Location'], '');
        final wordCountStr = CsvParser.getValue(row, ['字数', 'wordCount', 'word_count'], '');
        final wordCount = CsvParser.parseInt(wordCountStr) ?? content.length;

        // 创建日记条目（内容直接使用纯文本）
        final entry = DiaryEntry(
          id: _uuid.v4(),
          date: date,
          content: content,
          weather: weather.isNotEmpty ? weather : null,
          location: location.isNotEmpty ? location : null,
          wordCount: wordCount,
        );

        await DiaryDao.insert(entry);
        existingKeys.add(key);
        added++;
      } catch (e) {
        errors++;
        errorMessages.add('第$rowNum行：$e');
      }
    }

    return ImportResult(
      total: parsed.rows.length,
      added: added,
      updated: 0,
      skipped: skipped,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  /// 解析日期时间
  static DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      // 尝试多种日期格式
      DateTime? date;

      // yyyy-MM-dd
      final dashFormat = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
      // yyyy/MM/dd
      final slashFormat = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$');
      // yyyy年MM月dd日
      final chineseFormat = RegExp(r'^(\d{4})年(\d{1,2})月(\d{1,2})日$');

      RegExpMatch? match;
      if ((match = dashFormat.firstMatch(dateStr)) != null) {
        date = DateTime(
          int.parse(match!.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      } else if ((match = slashFormat.firstMatch(dateStr)) != null) {
        date = DateTime(
          int.parse(match!.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      } else if ((match = chineseFormat.firstMatch(dateStr)) != null) {
        date = DateTime(
          int.parse(match!.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }

      if (date == null) return null;

      // 解析时间
      if (timeStr.isNotEmpty) {
        final timeFormat = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
        final timeMatch = timeFormat.firstMatch(timeStr);
        if (timeMatch != null) {
          final hour = int.parse(timeMatch.group(1)!);
          final minute = int.parse(timeMatch.group(2)!);
          final second = timeMatch.group(3) != null
              ? int.parse(timeMatch.group(3)!)
              : 0;
          date = DateTime(date.year, date.month, date.day, hour, minute, second);
        }
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  /// 构建日记去重键
  static String _buildDiaryKey(DateTime date, String content) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
    return '$dateStr|${content.trim()}';
  }

  /// 从Quill JSON内容提取纯文本（兼容旧格式）
  static String _extractPlainTextFromContent(String content) {
    if (content.isEmpty) return '';
    try {
      final ops = jsonDecode(content) as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return content;
    }
  }
}
