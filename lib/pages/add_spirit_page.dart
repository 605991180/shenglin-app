import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';
import '../widgets/spirit_avatar.dart';
import '../widgets/gender_selector.dart';

class AddSpiritPage extends StatefulWidget {
  const AddSpiritPage({super.key});

  @override
  State<AddSpiritPage> createState() => _AddSpiritPageState();
}

class _AddSpiritPageState extends State<AddSpiritPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _preferenceController = TextEditingController();
  final _personalityController = TextEditingController();
  final _affinityController = TextEditingController();
  final _memoController = TextEditingController();
  String? _gender;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _preferenceController.dispose();
    _personalityController.dispose();
    _affinityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入姓名')),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final id = await SpiritDao.generateId();
    final age = int.tryParse(_ageController.text.trim());
    var spirit = Spirit(
      id: id,
      name: name,
      gender: _gender,
      age: age,
      preference: _preferenceController.text.trim().isEmpty
          ? null
          : _preferenceController.text.trim(),
      personality: _personalityController.text.trim().isEmpty
          ? null
          : _personalityController.text.trim(),
      affinity: _affinityController.text.trim().isEmpty
          ? null
          : _affinityController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
    );
    spirit = SpiritDao.prepareSpirit(spirit);
    await SpiritDao.insert(spirit);

    if (mounted) Navigator.pop(context, true);
  }

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
          '新增生灵',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: SpiritAvatar(
                size: 80,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('头像功能开发中')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Form card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTextField('姓名', _nameController, required: true),
                  _buildDivider(),
                  _buildGenderField(),
                  _buildDivider(),
                  _buildTextField('年龄', _ageController,
                      keyboardType: TextInputType.number, suffix: '岁'),
                  _buildDivider(),
                  _buildTextField('喜好', _preferenceController),
                  _buildDivider(),
                  _buildTextField('性格', _personalityController),
                  _buildDivider(),
                  _buildTextField('偏属', _affinityController),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Memo card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '备注',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '输入备注信息...',
                      hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false,
      TextInputType? keyboardType,
      String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
                if (required)
                  const Text(' *',
                      style: TextStyle(color: Colors.red, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: '请输入$label',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style:
                  const TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          if (suffix != null)
            Text(suffix,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            child: Text(
              '性别',
              style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GenderSelector(
              selectedGender: _gender,
              onChanged: (v) => setState(() => _gender = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}
