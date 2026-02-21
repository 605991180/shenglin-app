import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../database/diary_dao.dart';
import '../models/diary_entry.dart';
import 'diary_write_page.dart';

class DiaryDetailPage extends StatefulWidget {
  final String entryId;

  const DiaryDetailPage({super.key, required this.entryId});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  DiaryEntry? _entry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    final entry = await DiaryDao.getById(widget.entryId);
    setState(() {
      _entry = entry;
      _isLoading = false;
    });
  }

  Future<void> _editEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryWritePage(editEntryId: widget.entryId),
      ),
    );
    if (result == true) {
      _loadEntry();
    }
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这篇日记吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DiaryDao.delete(widget.entryId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _shareEntry() async {
    if (_entry == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }

  void _showImagePreview(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) => const Center(
                child: Icon(Icons.broken_image,
                    color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: _shareEntry,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _editEntry,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _deleteEntry();
              if (v == 'bookmark') _toggleBookmark();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'bookmark',
                child: Text(_entry?.isBookmarked == true ? '取消收藏' : '收藏'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entry == null
              ? const Center(child: Text('日记不存在'))
              : _buildContent(),
    );
  }

  Future<void> _toggleBookmark() async {
    if (_entry == null) return;
    final newVal = !_entry!.isBookmarked;
    await DiaryDao.toggleBookmark(widget.entryId, newVal);
    setState(() {
      _entry = _entry!.copyWith(isBookmarked: newVal);
    });
  }

  Widget _buildContent() {
    final entry = _entry!;
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${entry.date.year}年${entry.date.month}月${entry.date.day}日 ${weekDays[entry.date.weekday - 1]}';
    final timeStr = DateFormat('HH:mm').format(entry.date);

    final metaParts = <String>[timeStr];
    if (entry.weather != null && entry.weather!.isNotEmpty) {
      metaParts.add(entry.weather!);
    }
    if (entry.location != null && entry.location!.isNotEmpty) {
      metaParts.add(entry.location!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          // 元数据
          Text(
            metaParts.join(' \u00b7 '),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          // 正文
          _buildQuillContent(),
          // 图片
          if (entry.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImageGrid(),
          ],
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 8),
          // 底部信息
          Row(
            children: [
              Text(
                '${entry.wordCount}字',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFBBBBBB)),
              ),
              const SizedBox(width: 16),
              Icon(
                entry.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                size: 16,
                color: entry.isBookmarked
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFCCCCCC),
              ),
              const SizedBox(width: 4),
              Text(
                entry.isBookmarked ? '已收藏' : '未收藏',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuillContent() {
    if (_entry == null || _entry!.content.isEmpty) {
      return const Text(
        '(无内容)',
        style: TextStyle(fontSize: 15, color: Color(0xFFCCCCCC)),
      );
    }
    try {
      final doc = Document.fromJson(jsonDecode(_entry!.content));
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      return QuillEditor(
        controller: controller,
        focusNode: FocusNode(),
        scrollController: ScrollController(),
        config: QuillEditorConfig(
          showCursor: false,
          autoFocus: false,
          expands: false,
          padding: EdgeInsets.zero,
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                height: 1.6,
              ),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(4, 4),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      );
    } catch (_) {
      return Text(
        _entry!.content,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          height: 1.6,
        ),
      );
    }
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _entry!.imagePaths.map((path) {
        return GestureDetector(
          onTap: () => _showImagePreview(path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: 100,
                height: 100,
                color: const Color(0xFFF5F5F5),
                child: const Icon(Icons.broken_image,
                    color: Color(0xFFCCCCCC), size: 32),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
