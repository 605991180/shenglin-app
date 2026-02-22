import 'package:flutter/material.dart';

/// 导入结果统计
class ImportResult {
  final int total;
  final int added;
  final int updated;
  final int skipped;
  final int errors;
  final List<String> errorMessages;

  ImportResult({
    required this.total,
    required this.added,
    required this.updated,
    required this.skipped,
    required this.errors,
    List<String>? errorMessages,
  }) : errorMessages = errorMessages ?? [];

  bool get hasErrors => errors > 0 || errorMessages.isNotEmpty;
}

/// 导入结果弹窗
class ImportResultDialog extends StatelessWidget {
  final String title;
  final ImportResult result;

  const ImportResultDialog({
    super.key,
    required this.title,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.hasErrors ? Icons.warning_amber : Icons.check_circle,
            color: result.hasErrors ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('总计', result.total.toString(), null),
          const SizedBox(height: 8),
          _buildStatRow('新增', result.added.toString(), Colors.green),
          _buildStatRow('更新', result.updated.toString(), Colors.blue),
          _buildStatRow('跳过', result.skipped.toString(), Colors.grey),
          _buildStatRow('错误', result.errors.toString(), Colors.red),
          if (result.errorMessages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '错误详情:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errorMessages
                      .take(10)
                      .map((msg) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '- $msg',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (result.errorMessages.length > 10)
              Text(
                '... 还有${result.errorMessages.length - 10}条错误',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color? color) {
    String icon;
    switch (label) {
      case '新增':
        icon = '\u2705'; // ✅
        break;
      case '更新':
        icon = '\ud83d\udd04'; // 🔄
        break;
      case '跳过':
        icon = '\u23ed\ufe0f'; // ⏭️
        break;
      case '错误':
        icon = '\u274c'; // ❌
        break;
      default:
        icon = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon.isNotEmpty) ...[
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: color ?? const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

/// 导入确认弹窗
class ImportConfirmDialog extends StatelessWidget {
  final String title;
  final int recordCount;
  final String matchKey;
  final String? extraInfo;
  final VoidCallback onConfirm;

  const ImportConfirmDialog({
    super.key,
    required this.title,
    required this.recordCount,
    required this.matchKey,
    this.extraInfo,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('即将导入CSV文件：'),
          const SizedBox(height: 12),
          _buildInfoRow('\u2022 共$recordCount条记录'),
          _buildInfoRow('\u2022 以"$matchKey"为匹配键'),
          _buildInfoRow('\u2022 CSV非空字段将覆盖现有数据'),
          if (extraInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              extraInfo!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('开始导入'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      ),
    );
  }
}

/// 精养田缺失人员弹窗
class MissingSpiritDialog extends StatelessWidget {
  final List<String> missingNames;
  final VoidCallback onSkip;
  final VoidCallback onAddAndContinue;

  const MissingSpiritDialog({
    super.key,
    required this.missingNames,
    required this.onSkip,
    required this.onAddAndContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('发现未建档人员'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('以下人员不在生灵池：'),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingNames
                    .take(20)
                    .map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '\u2022 $name',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          if (missingNames.length > 20)
            Text(
              '... 还有${missingNames.length - 20}人',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 12),
          const Text(
            '是否同时添加到生灵池？',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Text(
            '（默认分类：政客）',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onSkip();
          },
          child: const Text('跳过'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAddAndContinue();
          },
          child: const Text('添加并继续'),
        ),
      ],
    );
  }
}

/// 日记导入模式选择弹窗
class DiaryImportModeDialog extends StatelessWidget {
  final int recordCount;
  final VoidCallback onAppend;
  final VoidCallback onOverwrite;

  const DiaryImportModeDialog({
    super.key,
    required this.recordCount,
    required this.onAppend,
    required this.onOverwrite,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入日记'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('即将导入 $recordCount 条日记记录'),
          const SizedBox(height: 16),
          const Text('请选择导入模式：'),
          const SizedBox(height: 8),
          const Text(
            '\u2022 追加导入：保留现有日记，仅添加新记录',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const Text(
            '\u2022 覆盖导入：清空现有日记后导入',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            onOverwrite();
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('覆盖导入'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAppend();
          },
          child: const Text('追加导入'),
        ),
      ],
    );
  }
}
