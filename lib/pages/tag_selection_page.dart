import 'package:flutter/material.dart';
import '../database/tag_dao.dart';
import '../models/tag.dart';
import '../widgets/tag_list_item.dart';
import 'edit_tag_page.dart';
import 'manage_tags_page.dart';

class TagSelectionPage extends StatefulWidget {
  final List<Tag> selectedTags;

  const TagSelectionPage({super.key, required this.selectedTags});

  @override
  State<TagSelectionPage> createState() => _TagSelectionPageState();
}

class _TagSelectionPageState extends State<TagSelectionPage> {
  List<Tag> _allTags = [];
  late Set<int> _selectedIds;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedTags
        .where((t) => t.id != null)
        .map((t) => t.id!)
        .toSet();
    _loadTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final tags = await TagDao.getAll();
    setState(() => _allTags = tags);
  }

  List<Tag> get _filteredTags {
    if (_searchQuery.isEmpty) return _allTags;
    return _allTags
        .where(
            (t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleTag(int tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
  }

  void _done() {
    final selected =
        _allTags.where((t) => _selectedIds.contains(t.id)).toList();
    Navigator.pop(context, selected);
  }

  Future<void> _openManage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ManageTagsPage()),
    );
    if (result == true) {
      await _loadTags();
      // Remove selected IDs that no longer exist
      final existingIds = _allTags.map((t) => t.id).toSet();
      _selectedIds.removeWhere((id) => !existingIds.contains(id));
      setState(() {});
    }
  }

  Future<void> _createTag() async {
    final result = await Navigator.push<Tag>(
      context,
      MaterialPageRoute(builder: (_) => const EditTagPage()),
    );
    if (result != null) {
      await _loadTags();
      if (result.id != null) {
        setState(() => _selectedIds.add(result.id!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTags;
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
          '选择标签',
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
            child: Text(
              '完成(${_selectedIds.length})',
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '搜索标签',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFFCCCCCC)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '我的标签',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                GestureDetector(
                  onTap: _openManage,
                  child: const Text(
                    '管理',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tag list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('暂无标签',
                        style: TextStyle(color: Color(0xFF999999))))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tag = filtered[index];
                      return TagListItem(
                        name: tag.name,
                        isSelected: _selectedIds.contains(tag.id),
                        onCheckTap: () => _toggleTag(tag.id!),
                      );
                    },
                  ),
          ),
          // Bottom create tag button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _createTag,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Color(0xFF2196F3), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '新建标签',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
