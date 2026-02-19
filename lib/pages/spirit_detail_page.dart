import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';
import '../models/tag.dart';
import '../widgets/spirit_avatar.dart';
import '../widgets/tag_chip.dart';
import 'edit_spirit_page.dart';
import 'tag_selection_page.dart';

class SpiritDetailPage extends StatefulWidget {
  final Spirit spirit;

  const SpiritDetailPage({super.key, required this.spirit});

  @override
  State<SpiritDetailPage> createState() => _SpiritDetailPageState();
}

class _SpiritDetailPageState extends State<SpiritDetailPage> {
  late Spirit _spirit;

  @override
  void initState() {
    super.initState();
    _spirit = widget.spirit;
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push<Spirit>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSpiritPage(spirit: _spirit),
      ),
    );
    if (result != null) {
      setState(() => _spirit = result);
    }
  }

  Future<void> _selectTags() async {
    final result = await Navigator.push<List<Tag>>(
      context,
      MaterialPageRoute(
        builder: (_) => TagSelectionPage(selectedTags: _spirit.tags),
      ),
    );
    if (result != null) {
      setState(() => _spirit.tags = result);
      await SpiritDao.updateSpiritTags(
          _spirit.id, result.where((t) => t.id != null).map((t) => t.id!).toList());
    }
  }

  String _genderIcon(String? gender) {
    switch (gender) {
      case '男':
        return '\u2642';
      case '女':
        return '\u2640';
      default:
        return '';
    }
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
          onPressed: () => Navigator.pop(context, _spirit),
        ),
        title: const Text(
          '生灵资料',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _openEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: const Text('保存',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(),
            const SizedBox(height: 16),
            // Basic info card
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            // Phone
            if (_spirit.phone.isNotEmpty) ...[
              _buildInfoRow('联系电话', _spirit.phone.first,
                  valueColor: const Color(0xFF2196F3), showArrow: true),
              const SizedBox(height: 16),
            ],
            // Tags
            _buildTagsSection(),
            const SizedBox(height: 16),
            // Memo
            _buildMemoSection(),
            const SizedBox(height: 16),
            // Photos
            _buildPhotosSection(),
            const SizedBox(height: 16),
            // Created time
            _buildInfoRow(
              '添加时间',
              DateFormat('yyyy-MM-dd HH:mm').format(_spirit.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SpiritAvatar(avatarPath: _spirit.avatar, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _spirit.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (_spirit.gender != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _genderIcon(_spirit.gender),
                        style: TextStyle(
                          fontSize: 16,
                          color: _spirit.gender == '女'
                              ? Colors.pink
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '编号: ${_spirit.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
                if (_spirit.typeLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _spirit.typeLabels
                        .map((l) => TagChip(
                              label: l,
                              backgroundColor: const Color(0xFFE3F2FD),
                              textColor: const Color(0xFF2196F3),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
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
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ),
          _buildDetailRow('姓名', _spirit.name),
          _buildDetailRow('性别', _spirit.gender ?? '未设置'),
          _buildDetailRow(
              '年龄', _spirit.age != null ? '${_spirit.age}岁' : '未设置'),
          _buildDetailRow('偏属', _spirit.affinity ?? '未设置'),
          _buildDetailRow('性格', _spirit.personality ?? '未设置',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return InkWell(
      onTap: _openEdit,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool showArrow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF999999)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? const Color(0xFF333333),
              ),
            ),
          ),
          if (showArrow)
            const Icon(Icons.chevron_right,
                size: 20, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
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
            '标签',
            style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._spirit.tags.map((tag) => TagChip(label: tag.name)),
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
                      Icon(Icons.add, size: 14, color: Color(0xFF4CAF50)),
                      SizedBox(width: 4),
                      Text('添加',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF4CAF50))),
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

  Widget _buildMemoSection() {
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
            '备忘记录',
            style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          Text(
            _spirit.memo ?? '暂无备忘',
            style: TextStyle(
              fontSize: 15,
              color: _spirit.memo != null
                  ? const Color(0xFF333333)
                  : const Color(0xFFCCCCCC),
            ),
          ),
        ],
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
            '照片',
            style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          if (_spirit.photos.isEmpty)
            const Text(
              '暂无照片',
              style: TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _spirit.photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: const Icon(Icons.image,
                        color: Colors.grey, size: 40),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
