import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';
import '../models/tag.dart';
import '../widgets/spirit_list_item.dart';
import '../widgets/alphabet_index.dart';
import 'spirit_detail_page.dart';

class TagMembersPage extends StatefulWidget {
  final Tag tag;

  const TagMembersPage({super.key, required this.tag});

  @override
  State<TagMembersPage> createState() => _TagMembersPageState();
}

class _TagMembersPageState extends State<TagMembersPage> {
  List<Spirit> _allSpirits = [];
  List<Spirit> _filteredSpirits = [];
  Map<String, List<Spirit>> _grouped = {};
  List<String> _letters = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void initState() {
    super.initState();
    _loadSpirits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSpirits() async {
    final spirits = await SpiritDao.getSpiritsByTagId(widget.tag.id!);
    setState(() {
      _allSpirits = spirits;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSpirits = List.from(_allSpirits);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredSpirits = _allSpirits
          .where((s) => s.name.toLowerCase().contains(q))
          .toList();
    }
    _buildGroups();
  }

  void _buildGroups() {
    final grouped = <String, List<Spirit>>{};
    for (final s in _filteredSpirits) {
      final letter = s.firstLetter ?? '#';
      grouped.putIfAbsent(letter, () => []).add(s);
    }
    final letters = grouped.keys.toList()..sort();
    if (letters.remove('#')) letters.add('#');

    _letterKeys.clear();
    for (final l in letters) {
      _letterKeys[l] = GlobalKey();
    }

    _grouped = grouped;
    _letters = letters;
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openDetail(Spirit spirit) async {
    final result = await Navigator.push<Spirit>(
      context,
      MaterialPageRoute(
        builder: (_) => SpiritDetailPage(spirit: spirit),
      ),
    );
    if (result != null) _loadSpirits();
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
        title: Text(
          '${widget.tag.name}(${_allSpirits.length})',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF333333)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中')),
              );
            },
          ),
        ],
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
          // Content
          Expanded(
            child: _filteredSpirits.isEmpty
                ? const Center(
                    child: Text('暂无联系人', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  )
                : Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          ..._buildGroupedList(),
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
                      if (_letters.isNotEmpty)
                        Positioned(
                          right: 2,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: AlphabetIndex(
                              letters: _letters,
                              onLetterTap: _scrollToLetter,
                              onTopTap: _scrollToTop,
                            ),
                          ),
                        ),
                    ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加 - 功能开发中')),
                  );
                },
                child: const Text(
                  '添加',
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('移出 - 功能开发中')),
                  );
                },
                child: const Text(
                  '移出',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE53935),
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

  List<Widget> _buildGroupedList() {
    final slivers = <Widget>[];
    for (final letter in _letters) {
      final spirits = _grouped[letter]!;
      // Letter header
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            key: _letterKeys[letter],
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ),
      );
      // Spirit items
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final spirit = spirits[index];
              return SpiritListItem(
                name: spirit.name,
                avatarPath: spirit.avatar,
                onTap: () => _openDetail(spirit),
              );
            },
            childCount: spirits.length,
          ),
        ),
      );
    }
    return slivers;
  }
}
