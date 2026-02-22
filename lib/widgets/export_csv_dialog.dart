import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/csv_export_helper.dart';

enum _ExportPhase { confirm, exporting, done, error }

class ExportCsvDialog extends StatefulWidget {
  final String filePrefix;
  final int recordCount;
  final List<String> headers;
  final Future<List<List<dynamic>>> Function() buildRows;

  const ExportCsvDialog({
    super.key,
    required this.filePrefix,
    required this.recordCount,
    required this.headers,
    required this.buildRows,
  });

  @override
  State<ExportCsvDialog> createState() => _ExportCsvDialogState();
}

class _ExportCsvDialogState extends State<ExportCsvDialog> {
  _ExportPhase _phase = _ExportPhase.confirm;
  File? _file;
  String _errorMsg = '';
  int _exportedCount = 0;

  Future<void> _startExport() async {
    setState(() => _phase = _ExportPhase.exporting);
    try {
      final rows = await widget.buildRows();
      _exportedCount = rows.length;

      final file = await CsvExportHelper.exportToCSV(
        filePrefix: widget.filePrefix,
        headers: widget.headers,
        dataRows: rows,
      );

      if (mounted) {
        setState(() {
          _file = file;
          _phase = _ExportPhase.done;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _phase = _ExportPhase.error;
        });
      }
    }
  }

  Future<void> _shareFile() async {
    if (_file != null) {
      await Share.shareXFiles(
        [XFile(_file!.path)],
        text: '${widget.filePrefix}数据导出',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '导出Excel',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _ExportPhase.confirm:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('即将导出全部数据为CSV表格：',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text('  \u2022  共 ${widget.recordCount} 条记录',
                style: const TextStyle(fontSize: 14)),
            const Text('  \u2022  可在Excel/WPS中编辑',
                style: TextStyle(fontSize: 14)),
            const Text('  \u2022  通过系统分享保存或发送',
                style: TextStyle(fontSize: 14)),
          ],
        );
      case _ExportPhase.exporting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('正在导出...', style: TextStyle(fontSize: 14)),
            if (_exportedCount > 0)
              Text('$_exportedCount/$_exportedCount 条',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF999999))),
            const SizedBox(height: 8),
          ],
        );
      case _ExportPhase.done:
        final fileName = _file!.path.split(RegExp(r'[/\\]')).last;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                SizedBox(width: 12),
                Text('导出完成',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text('已导出：$fileName',
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          ],
        );
      case _ExportPhase.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text('导出失败：$_errorMsg',
                style: const TextStyle(fontSize: 13, color: Colors.red)),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _ExportPhase.confirm:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: widget.recordCount > 0 ? _startExport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('立即导出'),
          ),
        ];
      case _ExportPhase.exporting:
        return [];
      case _ExportPhase.done:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
          ElevatedButton(
            onPressed: _shareFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('分享'),
          ),
        ];
      case _ExportPhase.error:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ];
    }
  }
}
