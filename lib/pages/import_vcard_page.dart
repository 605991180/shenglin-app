import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../utils/vcard_parser.dart';
import '../utils/pinyin_utils.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';

class ImportVcardPage extends StatefulWidget {
  const ImportVcardPage({super.key});

  @override
  State<ImportVcardPage> createState() => _ImportVcardPageState();
}

class _ImportVcardPageState extends State<ImportVcardPage> {
  List<Map<String, dynamic>>? _contacts;
  String? _fileName;
  String _conflictMode = 'skip'; // skip | overwrite | keep
  bool _importing = false;
  int _importProgress = 0;
  int _importTotal = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final content = await File(path).readAsString();
    final contacts = VcardParser.parse(content);

    setState(() {
      _fileName = file.name;
      _contacts = contacts;
    });
  }

  Future<void> _startImport() async {
    if (_contacts == null || _contacts!.isEmpty) return;
    setState(() {
      _importing = true;
      _importProgress = 0;
      _importTotal = _contacts!.length;
    });

    int imported = 0;
    for (int i = 0; i < _contacts!.length; i++) {
      final c = _contacts![i];
      final name = c['name'] as String;
      
      setState(() => _importProgress = i + 1);
      
      if (name.isEmpty) continue;

      final phones = c['phone'] as List<String>;
      final gender = c['gender'] as String?;

      // Check for duplicates by name
      final existing = await SpiritDao.search(name);
      final isDuplicate = existing.any((s) => s.name == name);

      if (isDuplicate) {
        if (_conflictMode == 'skip') {
          continue;
        } else if (_conflictMode == 'overwrite') {
          final target = existing.firstWhere((s) => s.name == name);
          final updated = target.copyWith(
            phone: phones.isNotEmpty ? phones : null,
            gender: gender,
          );
          final prepared = SpiritDao.prepareSpirit(updated);
          await SpiritDao.update(prepared);
          imported++;
          continue;
        }
        // 'keep' falls through to create new
      }

      final id = await SpiritDao.generateId();
      var spirit = Spirit(
        id: id,
        name: name,
        gender: gender,
        phone: phones,
      );
      spirit = SpiritDao.prepareSpirit(spirit);
      await SpiritDao.insert(spirit);
      imported++;
    }

    setState(() => _importing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $imported 个联系人')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContacts = _contacts != null && _contacts!.isNotEmpty;

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
          '导入 vCard 文件',
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
            // File picker card
            _buildFilePickerCard(),
            if (hasContacts) ...[
              const SizedBox(height: 8),
              _buildImportNote(),
              const SizedBox(height: 16),
              _buildPreviewCard(),
              const SizedBox(height: 16),
              _buildConflictCard(),
            ],
            const SizedBox(height: 24),
            _buildImportButton(hasContacts),
            if (_importing) ...[
              const SizedBox(height: 16),
              _buildProgressIndicator(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return GestureDetector(
      onTap: _importing ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.contact_page_outlined,
                color: Color(0xFF4CAF50),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fileName ?? '点击选择 .vcf 文件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _fileName != null
                    ? const Color(0xFF333333)
                    : const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '支持 vCard 2.1 / 3.0 / 4.0 规范',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportNote() {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '* 导入过程将在 $now 数据快照中执行。解析后的联系人会自动进入"生灵资料"编辑页。',
        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final contacts = _contacts!;
    final preview = contacts.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '将导入以下联系人',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          ...preview.asMap().entries.map((entry) {
            final c = entry.value;
            final name = c['name'] as String;
            final phones = c['phone'] as List<String>;
            final phone = phones.isNotEmpty ? phones.first : '';
            final initial = PinyinUtils.getFirstLetter(name);

            return Column(
              children: [
                if (entry.key > 0)
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Avatar with initial
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          if (contacts.length > 5) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '... 共 ${contacts.length} 个联系人',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '共 ${contacts.length} 个联系人',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '重复联系人处理',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          _buildRadioOption('skip', '跳过重复', '保留原有联系人，不导入重复项'),
          const SizedBox(height: 8),
          _buildRadioOption('overwrite', '覆盖现有', '用vCard中的信息更新已有联系人'),
          const SizedBox(height: 8),
          _buildRadioOption('keep', '保留两者', '导入为新的联系人'),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String title, String subtitle) {
    final isSelected = _conflictMode == value;
    return GestureDetector(
      onTap: () => setState(() => _conflictMode = value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFCCCCCC),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected
                        ? const Color(0xFF333333)
                        : const Color(0xFF666666),
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled && !_importing ? _startImport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          disabledBackgroundColor: Colors.grey[300],
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: _importing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                '开始导入',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _importTotal > 0 ? _importProgress / _importTotal : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '导入进度',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '$_importProgress / $_importTotal',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
