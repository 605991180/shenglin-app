import 'package:flutter/material.dart';
import '../database/tag_dao.dart';
import '../database/spirit_dao.dart';
import '../models/tag.dart';
import 'edit_tag_page.dart';
import 'manage_tags_page.dart';
import 'tag_members_page.dart';

class TagIndexPage extends StatefulWidget {
  const TagIndexPage({super.key});

  @override
  State<TagIndexPage> createState() => _TagIndexPageState();
}

class _TagIndexPageState extends State<TagIndexPage> {
  List<Tag> _allTags = [];
  List<Tag> _filteredTags = [];
  Map<int, int> _tagCounts = {};
  Map<int, List<String>> _tagNames = {};
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
    final names = <int, List<String>>{};
    for (final tag in tags) {
      if (tag.id != null) {
        names[tag.id!] = await SpiritDao.getSpiritNamesByTagId(tag.id!);
      }
    }
    setState(() {
      _allTags = tags;
      _tagCounts = counts;
      _tagNames = names;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTags = List.from(_allTags);
    } else {
      _filteredTags = _allTags
          .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  Future<void> _openTagMembers(Tag tag) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TagMembersPage(tag: tag),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _createTag() async {
    final result = await Navigator.push<Tag>(
      context,
      MaterialPageRoute(builder: (_) => const EditTagPage()),
    );
    if (result != null) _loadData();
  }

  Future<void> _openManage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageTagsPage()),
    );
    _loadData();
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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          '通讯录标签',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _searchQuery = v;
                setState(() => _applyFilter());
              },
              decoration: InputDecoration(
                hintText: '搜索',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Tag list
          Expanded(
            child: _filteredTags.isEmpty
                ? const Center(
                    child: Text('暂无标签', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredTags.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final tag = _filteredTags[index];
                      final count = _tagCounts[tag.id] ?? 0;
                      final names = _tagNames[tag.id] ?? [];
                      final summary = names.join(', ');
                      return _buildTagItem(tag, count, summary);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _createTag,
                child: const Text(
                  '新建',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: _openManage,
                child: const Text(
                  '编辑',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagItem(Tag tag, int count, String summary) {
    return InkWell(
      onTap: () => _openTagMembers(tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tag.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($count)',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
