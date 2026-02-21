import 'package:flutter/material.dart';
import '../database/diary_dao.dart';
import '../models/diary_entry.dart';
import '../widgets/weather_picker.dart';

class DiaryWritePage extends StatefulWidget {
  final String? editEntryId;

  const DiaryWritePage({super.key, this.editEntryId});

  @override
  State<DiaryWritePage> createState() => _DiaryWritePageState();
}

class _DiaryWritePageState extends State<DiaryWritePage> {
  final TextEditingController _textController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _weather;
  String? _location;
  bool _isLoading = true;
  bool _isSaving = false;
  DiaryEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.editEntryId != null) {
      final entry = await DiaryDao.getById(widget.editEntryId!);
      if (entry != null) {
        _existingEntry = entry;
        _date = entry.date;
        _weather = entry.weather;
        _location = entry.location;
        _textController.text = entry.content;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickWeather() async {
    final result = await WeatherPicker.show(context, current: _weather);
    if (result != null) {
      setState(() => _weather = result.isEmpty ? null : result);
    }
  }

  Future<void> _pickLocation() async {
    final controller = TextEditingController(text: _location ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '输入位置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '例如：北京 · 茶馆',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                  onPressed: () => Navigator.pop(ctx, controller.text),
                ),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('清除位置',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _location = result.isEmpty ? null : result);
    }
  }

  Future<void> _save() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();

    if (_existingEntry != null) {
      final updated = _existingEntry!.copyWith(
        date: _date,
        content: content,
        weather: _weather,
        location: _location,
        wordCount: content.length,
        updatedAt: now,
      );
      await DiaryDao.update(updated);
    } else {
      final entry = DiaryEntry(
        id: DiaryDao.generateId(),
        date: _date,
        content: content,
        weather: _weather,
        location: _location,
        wordCount: content.length,
        createdAt: now,
        updatedAt: now,
      );
      await DiaryDao.insert(entry);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateLabel =
        '${_date.month}月${_date.day}日 ${weekDays[_date.weekday - 1]}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          dateLabel,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? '保存中...' : '保存',
              style: TextStyle(
                color: _isSaving ? const Color(0xFFCCCCCC) : const Color(0xFF4CAF50),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 天气选择栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickWeather,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFF666666)),
                        const SizedBox(width: 4),
                        Text(
                          _weather ?? '天气',
                          style: TextStyle(
                            fontSize: 14,
                            color: _weather != null ? const Color(0xFF333333) : const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF999999)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _pickLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF666666)),
                        const SizedBox(width: 4),
                        Text(
                          _location ?? '位置',
                          style: TextStyle(
                            fontSize: 14,
                            color: _location != null ? const Color(0xFF333333) : const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF999999)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 文本输入区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  height: 1.8,
                ),
                decoration: const InputDecoration(
                  hintText: '记录今日...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFCCCCCC),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
