import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../database/diary_dao.dart';
import '../models/diary_entry.dart';

class DiaryExportDialog extends StatefulWidget {
  const DiaryExportDialog({super.key});

  @override
  State<DiaryExportDialog> createState() => _DiaryExportDialogState();
}

enum ExportRange { all, thisMonth, custom }

enum ExportFormat { markdown, txt }

class _DiaryExportDialogState extends State<DiaryExportDialog> {
  ExportRange _range = ExportRange.all;
  ExportFormat _format = ExportFormat.markdown;
  bool _includeDateTime = true;
  bool _includeWeatherLocation = true;
  bool _includeImages = true;
  bool _isExporting = false;
  int _totalCount = 0;
  int _monthCount = 0;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final total = await DiaryDao.getCount();
    final now = DateTime.now();
    final month = await DiaryDao.getCountByMonth(now.year, now.month);
    setState(() {
      _totalCount = total;
      _monthCount = month;
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _range = ExportRange.custom;
      });
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      // 获取日记列表
      List<DiaryEntry> entries;
      final now = DateTime.now();

      switch (_range) {
        case ExportRange.all:
          entries = await DiaryDao.getEntriesForExport();
          break;
        case ExportRange.thisMonth:
          entries = await DiaryDao.getByMonth(now.year, now.month);
          break;
        case ExportRange.custom:
          if (_customRange != null) {
            entries = await DiaryDao.getEntriesForExport(
              start: _customRange!.start,
              end: _customRange!.end
                  .add(const Duration(hours: 23, minutes: 59, seconds: 59)),
            );
          } else {
            entries = await DiaryDao.getEntriesForExport();
          }
          break;
      }

      if (entries.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有可导出的日记')),
          );
        }
        return;
      }

      // 生成内容
      final content = _format == ExportFormat.markdown
          ? _generateMarkdown(entries)
          : _generateTxt(entries);

      // 保存文件
      final ext = _format == ExportFormat.markdown ? 'md' : 'txt';
      final dateStr = DateFormat('yyyyMMdd').format(now);
      final fileName = '日记导出_$dateStr.$ext';

      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'diary_export'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final filePath = p.join(exportDir.path, fileName);
      await File(filePath).writeAsString(content);

      if (mounted) {
        Navigator.pop(context);
        // 分享文件
        await Share.shareXFiles(
          [XFile(filePath)],
          text: '日记导出',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _generateMarkdown(List<DiaryEntry> entries) {
    final buf = StringBuffer();
    buf.writeln('# 日记导出');
    buf.writeln();

    if (entries.length >= 2) {
      final first = DateFormat('yyyy-MM-dd').format(entries.last.date);
      final last = DateFormat('yyyy-MM-dd').format(entries.first.date);
      buf.writeln('$first 至 $last，共${entries.length}篇');
    }
    buf.writeln();
    buf.writeln('---');
    buf.writeln();

    for (final entry in entries) {
      const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekDay = weekDays[entry.date.weekday - 1];

      if (_includeDateTime) {
        buf.writeln(
            '## ${entry.date.year}年${entry.date.month.toString().padLeft(2, '0')}月${entry.date.day.toString().padLeft(2, '0')}日 $weekDay ${DateFormat('HH:mm').format(entry.date)}');
        buf.writeln();
      }

      if (_includeWeatherLocation) {
        if (entry.weather != null && entry.weather!.isNotEmpty) {
          buf.writeln('**天气**：${entry.weather}  ');
        }
        if (entry.location != null && entry.location!.isNotEmpty) {
          buf.writeln('**位置**：${entry.location}  ');
        }
        if (entry.wordCount > 0) {
          buf.writeln('**字数**：${entry.wordCount}字');
        }
        buf.writeln();
      }

      // 正文
      buf.writeln(_extractPlainText(entry));
      buf.writeln();

      if (_includeImages && entry.imagePaths.isNotEmpty) {
        for (final img in entry.imagePaths) {
          final name = p.basename(img);
          buf.writeln('[图片：$name]');
        }
        buf.writeln();
      }

      buf.writeln('---');
      buf.writeln();
    }

    return buf.toString();
  }

  String _generateTxt(List<DiaryEntry> entries) {
    final buf = StringBuffer();
    buf.writeln('日记导出');
    buf.writeln('========');
    buf.writeln();

    for (final entry in entries) {
      const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekDay = weekDays[entry.date.weekday - 1];

      if (_includeDateTime) {
        buf.writeln(
            '${entry.date.year}年${entry.date.month}月${entry.date.day}日 $weekDay ${DateFormat('HH:mm').format(entry.date)}');
      }

      if (_includeWeatherLocation) {
        final meta = <String>[];
        if (entry.weather != null && entry.weather!.isNotEmpty) {
          meta.add('天气：${entry.weather}');
        }
        if (entry.location != null && entry.location!.isNotEmpty) {
          meta.add('位置：${entry.location}');
        }
        if (meta.isNotEmpty) buf.writeln(meta.join('  '));
      }

      buf.writeln();
      buf.writeln(_extractPlainText(entry));
      buf.writeln();
      buf.writeln('────────────────────');
      buf.writeln();
    }

    return buf.toString();
  }

  String _extractPlainText(DiaryEntry entry) {
    if (entry.content.isEmpty) return '';
    try {
      final doc = Document.fromJson(jsonDecode(entry.content));
      return doc.toPlainText().trim();
    } catch (_) {
      return entry.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '导出日记',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 导出范围
            const Text('导出范围：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            RadioListTile<ExportRange>(
              title: Text('全部日记（共$_totalCount篇）',
                  style: const TextStyle(fontSize: 14)),
              value: ExportRange.all,
              groupValue: _range,
              onChanged: (v) => setState(() => _range = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<ExportRange>(
              title: Text('本月日记（$_monthCount篇）',
                  style: const TextStyle(fontSize: 14)),
              value: ExportRange.thisMonth,
              groupValue: _range,
              onChanged: (v) => setState(() => _range = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<ExportRange>(
              title: Row(
                children: [
                  const Text('自定义时间段',
                      style: TextStyle(fontSize: 14)),
                  if (_customRange != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('M/d').format(_customRange!.start)}-${DateFormat('M/d').format(_customRange!.end)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
              value: ExportRange.custom,
              groupValue: _range,
              onChanged: (_) => _pickCustomRange(),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Divider(),
            // 导出格式
            const Text('导出格式：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            RadioListTile<ExportFormat>(
              title: const Text('Markdown (.md)',
                  style: TextStyle(fontSize: 14)),
              value: ExportFormat.markdown,
              groupValue: _format,
              onChanged: (v) => setState(() => _format = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<ExportFormat>(
              title: const Text('纯文本 (.txt)',
                  style: TextStyle(fontSize: 14)),
              value: ExportFormat.txt,
              groupValue: _format,
              onChanged: (v) => setState(() => _format = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Divider(),
            // 包含内容
            const Text('包含内容：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            CheckboxListTile(
              title:
                  const Text('日期时间', style: TextStyle(fontSize: 14)),
              value: _includeDateTime,
              onChanged: (v) =>
                  setState(() => _includeDateTime = v ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title:
                  const Text('天气位置', style: TextStyle(fontSize: 14)),
              value: _includeWeatherLocation,
              onChanged: (v) =>
                  setState(() => _includeWeatherLocation = v ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('图片引用', style: TextStyle(fontSize: 14)),
              value: _includeImages,
              onChanged: (v) =>
                  setState(() => _includeImages = v ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消',
              style: TextStyle(color: Color(0xFF999999))),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: Text(_isExporting ? '导出中...' : '导出'),
        ),
      ],
    );
  }
}
