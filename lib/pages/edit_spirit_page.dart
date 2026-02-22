import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';
import '../models/tag.dart';
import '../widgets/gender_selector.dart';
import '../widgets/tag_chip.dart';
import 'tag_selection_page.dart';

class EditSpiritPage extends StatefulWidget {
  final Spirit spirit;

  const EditSpiritPage({super.key, required this.spirit});

  @override
  State<EditSpiritPage> createState() => _EditSpiritPageState();
}

class _EditSpiritPageState extends State<EditSpiritPage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _ethnicityController;
  late TextEditingController _idNumberController;
  late TextEditingController _primaryRelationController;
  late TextEditingController _affinityController;
  late TextEditingController _personalityController;
  late TextEditingController _memoController;
  late TextEditingController _identityLevelController;
  late List<TextEditingController> _phoneControllers;
  String? _gender;
  String? _identity;
  String? _identityLevel;
  List<Tag> _tags = [];
  List<String> _photos = [];

  static const List<String> _identityTypes = ['政客', '商人', '异士', '群众'];
  static const List<String> _politicianLevels = [
    '村级', '职员', '股级', '副科', '正科', '副处', '正处', '副厅', '正厅', '副部', '正部',
  ];
  static const List<String> _merchantLevels = [
    '千级', '万级', '十万级', '五十万级', '百万级', '千万级', '亿级',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.spirit;
    _nameController = TextEditingController(text: s.name);
    _ageController = TextEditingController(text: s.age?.toString() ?? '');
    _ethnicityController = TextEditingController(text: s.ethnicity ?? '');
    _idNumberController = TextEditingController(text: s.idNumber ?? '');
    _primaryRelationController = TextEditingController(text: s.primaryRelation ?? '');
    _affinityController = TextEditingController(text: s.affinity ?? '');
    _personalityController = TextEditingController(text: s.personality ?? '');
    _memoController = TextEditingController(text: s.memo ?? '');
    _gender = s.gender;
    _identity = s.identity;
    _identityLevel = s.identityLevel;
    _identityLevelController = TextEditingController(
      text: (_identity == '异士' || _identity == '群众') ? (s.identityLevel ?? '') : '',
    );
    _tags = List.from(s.tags);
    _photos = List.from(s.photos);
    _phoneControllers = s.phone.isEmpty
        ? [TextEditingController()]
        : s.phone.map((p) => TextEditingController(text: p)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _ethnicityController.dispose();
    _idNumberController.dispose();
    _primaryRelationController.dispose();
    _affinityController.dispose();
    _personalityController.dispose();
    _memoController.dispose();
    _identityLevelController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _done() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('姓名不能为空')),
      );
      return;
    }

    final phones = _phoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    var updated = widget.spirit.copyWith(
      name: name,
      gender: _gender,
      age: int.tryParse(_ageController.text.trim()),
      ethnicity: _ethnicityController.text.trim().isEmpty
          ? null
          : _ethnicityController.text.trim(),
      idNumber: _idNumberController.text.trim().isEmpty
          ? null
          : _idNumberController.text.trim(),
      identity: _identity,
      identityLevel: _getIdentityLevelValue(),
      primaryRelation: _primaryRelationController.text.trim().isEmpty
          ? null
          : _primaryRelationController.text.trim(),
      affinity: _affinityController.text.trim().isEmpty
          ? null
          : _affinityController.text.trim(),
      personality: _personalityController.text.trim().isEmpty
          ? null
          : _personalityController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      phone: phones,
      photos: _photos,
      tags: _tags,
    );
    updated = SpiritDao.prepareSpirit(updated);
    await SpiritDao.update(updated);
    await SpiritDao.updateSpiritTags(
        updated.id, _tags.where((t) => t.id != null).map((t) => t.id!).toList());

    if (mounted) Navigator.pop(context, updated);
  }

  Future<void> _selectTags() async {
    final result = await Navigator.push<List<Tag>>(
      context,
      MaterialPageRoute(
        builder: (_) => TagSelectionPage(selectedTags: _tags),
      ),
    );
    if (result != null) {
      setState(() => _tags = result);
    }
  }

  void _addPhone() {
    setState(() => _phoneControllers.add(TextEditingController()));
  }

  String? _getIdentityLevelValue() {
    if (_identity == null) return null;
    if (_identity == '异士' || _identity == '群众') {
      final text = _identityLevelController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _identityLevel;
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF2196F3), fontSize: 15),
          ),
        ),
        title: const Text(
          '资料编辑',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _done,
            child: const Text(
              '完成',
              style: TextStyle(
                color: Color(0xFF2196F3),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo management
            _buildPhotosSection(),
            const SizedBox(height: 16),
            // Basic info card
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            // Contact info
            _buildContactCard(),
            const SizedBox(height: 16),
            // Tags
            _buildTagsCard(),
            const SizedBox(height: 16),
            // Memo
            _buildMemoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
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
            '照片管理',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._photos.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 40),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(entry.key),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('照片功能开发中')),
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Color(0xFFCCCCCC), size: 24),
                      Text('添加',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFCCCCCC))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '基本信息',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildEditRow('姓名', _nameController),
          _buildDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 70,
                  child: Text('性别',
                      style:
                          TextStyle(fontSize: 15, color: Color(0xFF333333))),
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
          ),
          _buildDivider(),
          _buildEditRow('年龄', _ageController,
              keyboardType: TextInputType.number, suffix: '岁'),
          _buildDivider(),
          _buildEditRow('民族', _ethnicityController),
          _buildDivider(),
          _buildEditRow('身份证号', _idNumberController,
              keyboardType: TextInputType.number),
          _buildDivider(),
          // 主要身份
          _buildIdentitySection(),
          _buildDivider(),
          _buildEditRow('主要关系', _primaryRelationController),
          _buildDivider(),
          _buildEditRow('偏属', _affinityController),
          _buildDivider(),
          _buildEditRow('性格', _personalityController),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '联系方式',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ..._phoneControllers.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '输入电话号码',
                        hintStyle:
                            const TextStyle(color: Color(0xFFCCCCCC)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF333333)),
                    ),
                  ),
                  if (entry.key == 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('主联系人',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF999999))),
                    ),
                ],
              ),
            );
          }),
          GestureDetector(
            onTap: _addPhone,
            child: const Row(
              children: [
                Icon(Icons.add_circle, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Text(
                  '添加联系电话',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
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
            '标签',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((tag) => TagChip(label: tag.name)),
              GestureDetector(
                onTap: _selectTags,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF999999)),
                      SizedBox(width: 4),
                      Text('添加',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoCard() {
    return Container(
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
            '备忘',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '输入备忘信息...',
              hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + type selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 70,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('主要身份',
                      style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _identityTypes.map((type) {
                    final isSelected = _identity == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _identity = isSelected ? null : type;
                          _identityLevel = null;
                          _identityLevelController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // Level selector (only when identity is selected)
          if (_identity != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 70,
                  child: Text('身份等级',
                      style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildLevelSelector()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    if (_identity == '政客') {
      return _buildDropdownLevel(_politicianLevels);
    } else if (_identity == '商人') {
      return _buildDropdownLevel(_merchantLevels);
    } else {
      // 异士 / 群众 → 自由录入
      return TextField(
        controller: _identityLevelController,
        decoration: InputDecoration(
          hintText: '请输入$_identity等级或描述',
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
      );
    }
  }

  Widget _buildDropdownLevel(List<String> levels) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: levels.contains(_identityLevel) ? _identityLevel : null,
          isExpanded: true,
          hint: const Text('请选择等级',
              style: TextStyle(fontSize: 15, color: Color(0xFFCCCCCC))),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF999999)),
          style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
          items: levels
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) => setState(() => _identityLevel = v),
        ),
      ),
    );
  }

  Widget _buildEditRow(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333))),
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
                style:
                    const TextStyle(fontSize: 15, color: Color(0xFF999999))),
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
