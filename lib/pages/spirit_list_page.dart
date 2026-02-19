import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../models/spirit.dart';
import '../widgets/spirit_list_item.dart';
import '../widgets/alphabet_index.dart';
import 'add_spirit_page.dart';
import 'settings_page.dart';
import 'spirit_detail_page.dart';

class SpiritListPage extends StatefulWidget {
  const SpiritListPage({super.key});

  @override
  State<SpiritListPage> createState() => _SpiritListPageState();
}

class _SpiritListPageState extends State<SpiritListPage> {
  List<Spirit> _allSpirits = [];
  Map<String, List<Spirit>> _grouped = {};
  List<String> _letters = [];
  int _totalCount = 0;
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
    final spirits = _searchQuery.isEmpty
        ? await SpiritDao.getAll()
        : await SpiritDao.search(_searchQuery);
    final count = await SpiritDao.getCount();
    final grouped = <String, List<Spirit>>{};
    for (final s in spirits) {
      final letter = s.firstLetter ?? '#';
      grouped.putIfAbsent(letter, () => []).add(s);
    }
    final letters = grouped.keys.toList()..sort();
    // Move '#' to end
    if (letters.remove('#')) letters.add('#');

    _letterKeys.clear();
    for (final l in letters) {
      _letterKeys[l] = GlobalKey();
    }

    setState(() {
      _allSpirits = spirits;
      _grouped = grouped;
      _letters = letters;
      _totalCount = count;
    });
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

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSpiritPage()),
    );
    if (result == true) _loadSpirits();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
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

  String _buildSubtitle(Spirit s) {
    final parts = <String>[];
    if (s.affinity != null && s.affinity!.isNotEmpty) parts.add(s.affinity!);
    if (s.personality != null && s.personality!.isNotEmpty) {
      parts.add(s.personality!);
    }
    return parts.isEmpty ? '' : parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),
                // Search
                SliverToBoxAdapter(child: _buildSearchBar()),
                // Stats banner
                SliverToBoxAdapter(child: _buildStatsBanner()),
                // Tag index banner
                SliverToBoxAdapter(child: _buildTagIndexBanner()),
                // Spirit list grouped by letter
                ..._buildGroupedList(),
                // Bottom padding
                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)),
              ],
            ),
            // Alphabet index on the right
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
            ),
            child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            '生灵池',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: Color(0xFF333333), size: 24),
            onPressed: _openAdd,
          ),
          IconButton(
            icon:
                const Icon(Icons.menu, color: Color(0xFF333333), size: 24),
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          _searchQuery = v;
          _loadSpirits();
        },
        decoration: InputDecoration(
          hintText: '搜索生灵、属性或标签...',
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              '池中生灵合计',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 12),
            Text(
              '$_totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagIndexBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '成',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '生灵标签',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withAlpha(38),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '索引',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: Color(0xFF4CAF50), size: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final slivers = <Widget>[];
    if (_allSpirits.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 64, color: Color(0xFFDDDDDD)),
                SizedBox(height: 12),
                Text('暂无生灵',
                    style:
                        TextStyle(fontSize: 16, color: Color(0xFF999999))),
                SizedBox(height: 4),
                Text('点击右上角 + 添加',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
              ],
            ),
          ),
        ),
      );
      return slivers;
    }

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
      // Spirit items in this group
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final spirit = spirits[index];
              return SpiritListItem(
                name: spirit.name,
                subtitle: _buildSubtitle(spirit),
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
