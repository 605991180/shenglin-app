import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../utils/csv_export_helper.dart';
import '../widgets/export_csv_dialog.dart';
import 'import_vcard_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '通讯设置',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Group 1: Import/Export
            _buildCard([
              _buildItem(
                Icons.contacts_outlined,
                '从通讯录导入',
                onTap: () => _openVcardImport(),
              ),
              _buildDivider(),
              _buildItem(
                Icons.table_chart_outlined,
                '导出Excel',
                onTap: () => _showCsvExportDialog(),
              ),
            ]),
            const SizedBox(height: 16),
            // Group 2: Batch
            _buildCard([
              _buildItem(
                Icons.checklist_outlined,
                '批量整理',
                onTap: () => _showTodo('批量整理'),
              ),
            ]),
            const SizedBox(height: 16),
            // Group 3: About
            _buildCard([
              _buildItem(
                Icons.help_outline,
                '帮助与反馈',
                onTap: () => _showTodo('帮助与反馈'),
              ),
              _buildDivider(),
              _buildItem(
                Icons.info_outline,
                '关于',
                onTap: () => _showTodo('关于'),
              ),
            ]),
            const SizedBox(height: 32),
            // Version info
            const Text(
              '生灵池 版本 4.2.0 (2026.02.22)',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 4),
            const Text(
              '\u00a9 2026 Lifepool Tech.',
              style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF999999)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Text(
              '\u203A',
              style: TextStyle(fontSize: 20, color: Color(0xFFCCCCCC)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }

  Future<void> _openVcardImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ImportVcardPage()),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showCsvExportDialog() async {
    final count = await SpiritDao.getCount();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => ExportCsvDialog(
        filePrefix: '生灵池',
        recordCount: count,
        headers: CsvExportHelper.spiritHeaders,
        buildRows: CsvExportHelper.buildSpiritRows,
      ),
    );
  }

  void _showTodo(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - 功能开发中')),
    );
  }
}
