import 'package:flutter/material.dart';
import '../database/tag_dao.dart';
import '../models/tag.dart';
import '../widgets/tag_list_item.dart';
import 'edit_tag_page.dart';

class ManageTagsPage extends StatefulWidget {
  const ManageTagsPage({super.key});

  @override
  State<ManageTagsPage> createState() => _ManageTagsPageState();
}

class _ManageTagsPageState extends State<ManageTagsPage> {
  List<Tag> _tags = [];
  Map<int, int> _tagCounts = {};
  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tags = await TagDao.getAll();
    final counts = await TagDao.getTagSpiritCounts();
    setState(() {
      _tags = tags;
      _tagCounts = counts;
    });
  }

  List<Tag> get _filteredTags {
    if (_searchQuery.isEmpty) return _tags;
    return _tags
        .where(
            (t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleSelect(int tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredTags.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(_filteredTags.map((t) => t.id!));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清理'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个标签吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TagDao.deleteMultiple(_selectedIds.toList());
      _selectedIds.clear();
      await _loadData();
    }
  }

  Future<void> _editTag(Tag tag) async {
    final result = await Navigator.push<Tag>(
      context,
      MaterialPageRoute(builder: (_) => EditTagPage(tag: tag)),
    );
    if (result != null) {
      await _loadData();
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
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          '管理标签',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedIds.length == filtered.length && filtered.isNotEmpty
                  ? '取消全选'
                  : '全选',
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 15,
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
                hintText: '搜索',
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
                        count: _tagCounts[tag.id] ?? 0,
                        onCheckTap: () => _toggleSelect(tag.id!),
                        onTap: () => _editTag(tag),
                      );
                    },
                  ),
          ),
          // Bottom delete button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(
                    '清理(${_selectedIds.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIds.isEmpty
                        ? Colors.grey[300]
                        : Colors.red[400],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
