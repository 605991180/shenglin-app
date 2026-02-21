import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/diary_dao.dart';
import '../models/diary_entry.dart';
import '../widgets/diary_calendar.dart';
import '../widgets/diary_card.dart';
import '../widgets/diary_export_dialog.dart';
import 'diary_detail_page.dart';
import 'diary_write_page.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  List<DiaryEntry> _entries = [];
  Set<int> _datesWithEntries = {};
  DateTime _selectedDate = DateTime.now();
  bool _calendarExpanded = false;
  bool _isLoading = true;
  bool _isSearching = false;
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
    setState(() => _isLoading = true);
    try {
      final entries = await DiaryDao.getAll();
      final dots = await DiaryDao.getDatesWithEntries(
          _selectedDate.year, _selectedDate.month);
      setState(() {
        _entries = entries;
        _datesWithEntries = dots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDots() async {
    final dots = await DiaryDao.getDatesWithEntries(
        _selectedDate.year, _selectedDate.month);
    setState(() => _datesWithEntries = dots);
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadData();
      return;
    }
    setState(() => _isLoading = true);
    final results = await DiaryDao.search(query.trim());
    setState(() {
      _entries = results;
      _isLoading = false;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _calendarExpanded = false;
    });
    // 滚动到该日期的日记（如果有）
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _selectedDate = DateTime(month.year, month.month, _selectedDate.day);
    });
    _loadDots();
  }

  Future<void> _openWritePage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const DiaryWritePage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openDetail(DiaryEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DiaryDetailPage(entryId: entry.id)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (_) => const DiaryExportDialog(),
    );
  }

  // 按天分组
  Map<String, List<DiaryEntry>> _groupByDay() {
    final map = <String, List<DiaryEntry>>{};
    for (final e in _entries) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDay = weekDays[date.weekday - 1];

    if (target == today) {
      return '今天  $weekDay';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (target == yesterday) {
      return '昨天  $weekDay';
    }
    if (date.year == now.year) {
      return '${date.month}月${date.day}日  $weekDay';
    }
    return '${date.year}年${date.month}月${date.day}日  $weekDay';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final todayLabel =
        '${now.month}月${now.day}日  ${weekDays[now.weekday - 1]}';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索日记内容...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
                ),
                style:
                    const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                onChanged: _onSearch,
              )
            : GestureDetector(
                onTap: () {
                  setState(
                      () => _calendarExpanded = !_calendarExpanded);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      todayLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Icon(
                      _calendarExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF666666),
                      size: 20,
                    ),
                  ],
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _loadData();
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, size: 22),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share, size: 20),
              onPressed: _showExportDialog,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 可收缩日历
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8),
              child: DiaryCalendar(
                selectedDate: _selectedDate,
                datesWithEntries: _datesWithEntries,
                onDateSelected: _onDateSelected,
                onMonthChanged: _onMonthChanged,
                isExpanded: _calendarExpanded,
                onToggleExpand: () =>
                    setState(() => _calendarExpanded = !_calendarExpanded),
              ),
            ),
            crossFadeState: _calendarExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          // 时间轴列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildTimeline(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openWritePage,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined,
              size: 64, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 16),
          const Text(
            '还没有日记',
            style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角按钮开始记录',
            style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final grouped = _groupByDay();
    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: dayKeys.length,
      itemBuilder: (context, index) {
        final dayKey = dayKeys[index];
        final dayEntries = grouped[dayKey]!;
        final date = dayEntries.first.date;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期分割标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
              child: Text(
                _dayLabel(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                  color: const Color(0xFFEEEEEE).withAlpha(180), height: 1),
            ),
            const SizedBox(height: 4),
            // 该天的日记卡片
            ...dayEntries.map((entry) => DiaryCard(
                  entry: entry,
                  onTap: () => _openDetail(entry),
                )),
          ],
        );
      },
    );
  }
}
