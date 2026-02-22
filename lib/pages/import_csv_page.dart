import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../utils/csv_parser.dart';
import '../utils/pinyin_utils.dart';
import '../database/spirit_dao.dart';
import '../database/tag_dao.dart';
import '../models/spirit.dart';
import '../models/tag.dart';

class ImportCsvPage extends StatefulWidget {
  const ImportCsvPage({super.key});

  @override
  State<ImportCsvPage> createState() => _ImportCsvPageState();
}

class _ImportCsvPageState extends State<ImportCsvPage> {
  List<Map<String, dynamic>>? _contacts;
  String? _fileName;
  String _conflictMode = 'skip'; // skip | overwrite | keep
  bool _importing = false;
  int _importProgress = 0;
  int _importTotal = 0;

  /// 根据标签名列表获取或创建标签，返回标签ID列表
  Future<List<int>> _getOrCreateTagIds(List<String> tagNames) async {
    if (tagNames.isEmpty) return [];
    final tagIds = <int>[];
    for (final name in tagNames) {
      if (name.trim().isEmpty) continue;
      final trimmedName = name.trim();
      // 查找是否已存在
      var tag = await TagDao.getByName(trimmedName);
      if (tag == null) {
        // 不存在则创建新标签
        final newId = await TagDao.insert(Tag(name: trimmedName));
        tagIds.add(newId);
      } else {
        tagIds.add(tag.id!);
      }
    }
    return tagIds;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final content = await File(path).readAsString();
    final parsed = CsvParser.parse(content);

    final contacts = parsed.rows.map((row) {
      return <String, dynamic>{
        'name': CsvParser.getValue(row, ['姓名', 'name', 'Name'], ''),
        'phone': CsvParser.parseListField(
            CsvParser.getValue(row, ['电话', 'phone', 'Phone'], '')),
        'gender': CsvParser.getValue(row, ['性别', 'gender', 'Gender'], ''),
        'age': CsvParser.parseInt(
            CsvParser.getValue(row, ['年龄', 'age', 'Age'], '')),
        'ethnicity':
            CsvParser.getValue(row, ['民族', 'ethnicity', 'Ethnicity'], ''),
        'idNumber':
            CsvParser.getValue(row, ['身份证号', 'idNumber', 'id_number'], ''),
        'identity':
            CsvParser.getValue(row, ['身份', 'identity', 'Identity'], ''),
        'identityLevel': CsvParser.getValue(
            row, ['身份层级', 'identityLevel', 'identity_level'], ''),
        'primaryRelation': CsvParser.getValue(
            row, ['首要关系', 'primaryRelation', 'primary_relation'], ''),
        'preference':
            CsvParser.getValue(row, ['偏好', 'preference', 'Preference'], ''),
        'personality': CsvParser.getValue(
            row, ['性格', 'personality', 'Personality'], ''),
        'affinity':
            CsvParser.getValue(row, ['偏属', '亲密度', 'affinity', 'Affinity'], ''),
        'memo': CsvParser.getValue(row, ['备忘', 'memo', 'Memo'], ''),
        'typeLabels': CsvParser.parseListField(
            CsvParser.getValue(row, ['分类标签', 'typeLabels', 'type_labels'], '')),
      };
    }).where((c) => (c['name'] as String).isNotEmpty).toList();

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
      final gender = c['gender'] as String;
      final age = c['age'] as int?;
      final ethnicity = c['ethnicity'] as String;
      final idNumber = c['idNumber'] as String;
      final identity = c['identity'] as String;
      final identityLevel = c['identityLevel'] as String;
      final primaryRelation = c['primaryRelation'] as String;
      final preference = c['preference'] as String;
      final personality = c['personality'] as String;
      final affinity = c['affinity'] as String;
      final memo = c['memo'] as String;
      final typeLabels = c['typeLabels'] as List<String>;

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
            gender: gender.isNotEmpty ? gender : null,
            age: age,
            ethnicity: ethnicity.isNotEmpty ? ethnicity : null,
            idNumber: idNumber.isNotEmpty ? idNumber : null,
            identity: identity.isNotEmpty ? identity : null,
            identityLevel: identityLevel.isNotEmpty ? identityLevel : null,
            primaryRelation:
                primaryRelation.isNotEmpty ? primaryRelation : null,
            preference: preference.isNotEmpty ? preference : null,
            personality: personality.isNotEmpty ? personality : null,
            affinity: affinity.isNotEmpty ? affinity : null,
            memo: memo.isNotEmpty ? memo : null,
            typeLabels: typeLabels.isNotEmpty ? typeLabels : null,
          );
          final prepared = SpiritDao.prepareSpirit(updated);
          await SpiritDao.update(prepared);
          // 更新标签关联
          if (typeLabels.isNotEmpty) {
            final tagIds = await _getOrCreateTagIds(typeLabels);
            await SpiritDao.updateSpiritTags(target.id, tagIds);
          }
          imported++;
          continue;
        }
        // 'keep' falls through to create new
      }

      final id = await SpiritDao.generateId();
      var spirit = Spirit(
        id: id,
        name: name,
        gender: gender.isNotEmpty ? gender : null,
        phone: phones,
        age: age,
        ethnicity: ethnicity.isNotEmpty ? ethnicity : null,
        idNumber: idNumber.isNotEmpty ? idNumber : null,
        identity: identity.isNotEmpty ? identity : null,
        identityLevel: identityLevel.isNotEmpty ? identityLevel : null,
        primaryRelation: primaryRelation.isNotEmpty ? primaryRelation : null,
        preference: preference.isNotEmpty ? preference : null,
        personality: personality.isNotEmpty ? personality : null,
        affinity: affinity.isNotEmpty ? affinity : null,
        memo: memo.isNotEmpty ? memo : null,
        typeLabels: typeLabels,
      );
      spirit = SpiritDao.prepareSpirit(spirit);
      await SpiritDao.insert(spirit);
      // 创建并关联标签
      if (typeLabels.isNotEmpty) {
        final tagIds = await _getOrCreateTagIds(typeLabels);
        await SpiritDao.updateSpiritTags(id, tagIds);
      }
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
          '导入 Excel 文件',
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
                Icons.table_chart_outlined,
                color: Color(0xFF4CAF50),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fileName ?? '点击选择 .csv 文件',
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
              '支持标准 CSV 格式',
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
          _buildRadioOption('overwrite', '覆盖现有', '用CSV中的信息更新已有联系人'),
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
