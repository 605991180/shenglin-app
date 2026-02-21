import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  DateTime _date = DateTime.now();
  String? _weather;
  String? _location;
  bool _isBookmarked = false;
  List<String> _imagePaths = [];
  int _wordCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  Timer? _autoSaveTimer;
  String? _draftId;
  DiaryEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _quillController.document.changes.listen((_) {
      _updateWordCount();
    });
    _loadInitialData();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.editEntryId != null) {
      // 编辑现有日记
      final entry = await DiaryDao.getById(widget.editEntryId!);
      if (entry != null) {
        _existingEntry = entry;
        _date = entry.date;
        _weather = entry.weather;
        _location = entry.location;
        _isBookmarked = entry.isBookmarked;
        _imagePaths = List.from(entry.imagePaths);
        if (entry.content.isNotEmpty) {
          try {
            final doc = Document.fromJson(jsonDecode(entry.content));
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _quillController.document.changes.listen((_) {
              _updateWordCount();
            });
          } catch (_) {
            // 内容解析失败，使用空文档
          }
        }
      }
    } else {
      // 新建日记，检查是否有草稿
      final draft = await DiaryDao.getDraft();
      if (draft != null) {
        _draftId = draft.id;
        _imagePaths = List.from(draft.imagePaths);
        if (draft.content.isNotEmpty) {
          try {
            final doc = Document.fromJson(jsonDecode(draft.content));
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _quillController.document.changes.listen((_) {
              _updateWordCount();
            });
          } catch (_) {}
        }
      }
    }
    _updateWordCount();
    setState(() => _isLoading = false);
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    _draftId ??= DiaryDao.generateId();
    final draft = DiaryDraft(
      id: _draftId!,
      diaryId: widget.editEntryId,
      content: content,
      imagePaths: _imagePaths,
    );
    await DiaryDao.saveDraft(draft);
  }

  void _updateWordCount() {
    final text = _quillController.document.toPlainText().trim();
    setState(() => _wordCount = text.length);
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多添加3张图片')),
      );
      return;
    }

    final picker = ImagePicker();
    final remaining = 3 - _imagePaths.length;
    final images = await picker.pickMultiImage(
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    final toAdd = images.take(remaining).toList();
    final appDir = await getApplicationDocumentsDirectory();
    final diaryImgDir = Directory(p.join(appDir.path, 'diary_images'));
    if (!await diaryImgDir.exists()) {
      await diaryImgDir.create(recursive: true);
    }

    for (final img in toAdd) {
      final ext = p.extension(img.path);
      final newName =
          'diary_${DateTime.now().millisecondsSinceEpoch}$ext';
      final newPath = p.join(diaryImgDir.path, newName);
      await File(img.path).copy(newPath);
      _imagePaths.add(newPath);
    }
    setState(() {});
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? _date.hour,
          time?.minute ?? _date.minute,
        );
      });
    }
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
      backgroundColor: const Color(0xFF2C2C2E),
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
                color: Color(0xFFE8E8E8),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Color(0xFFE8E8E8)),
              decoration: InputDecoration(
                hintText: '例如：北京 · 茶馆',
                hintStyle: const TextStyle(color: Color(0xFF636366)),
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
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final content =
        jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();
    final now = DateTime.now();

    if (_existingEntry != null) {
      // 更新
      final updated = _existingEntry!.copyWith(
        date: _date,
        content: content,
        imagePaths: _imagePaths,
        weather: _weather,
        location: _location,
        wordCount: plainText.length,
        isBookmarked: _isBookmarked,
        updatedAt: now,
      );
      await DiaryDao.update(updated);
    } else {
      // 新建
      final entry = DiaryEntry(
        id: DiaryDao.generateId(),
        date: _date,
        content: content,
        imagePaths: _imagePaths,
        weather: _weather,
        location: _location,
        wordCount: plainText.length,
        isBookmarked: _isBookmarked,
        createdAt: now,
        updatedAt: now,
      );
      await DiaryDao.insert(entry);
    }

    // 删除草稿
    if (_draftId != null) {
      await DiaryDao.deleteDraft(_draftId!);
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
        backgroundColor: Color(0xFF1C1C1E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
      );
    }

    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateLabel =
        '${_date.month}月${_date.day}日 / ${DateFormat('HH:mm').format(_date)} ${weekDays[_date.weekday - 1]}';

    const bgColor = Color(0xFF1C1C1E);
    const dividerColor = Color(0xFF3A3A3C);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveDraft();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // 顶栏
              _buildTopBar(dateLabel),
              const Divider(height: 1, color: dividerColor),
              // 编辑区域
              Expanded(
                child: Theme(
                  data: ThemeData.dark().copyWith(
                    canvasColor: bgColor,
                    scaffoldBackgroundColor: bgColor,
                    colorScheme: const ColorScheme.dark(
                      surface: Color(0xFF1C1C1E),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quill编辑器
                        Expanded(
                          child: QuillEditor(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                            config: QuillEditorConfig(
                              placeholder: '记录今日...',
                              padding: EdgeInsets.zero,
                              autoFocus: widget.editEntryId == null,
                              expands: true,
                              customStyles: DefaultStyles(
                                paragraph: DefaultTextBlockStyle(
                                  const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFE8E8E8),
                                    height: 1.8,
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(4, 4),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                placeHolder: DefaultTextBlockStyle(
                                  const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF636366),
                                    height: 1.8,
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(4, 4),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 图片区
                        _buildImageSection(),
                      ],
                    ),
                  ),
                ),
              ),
              // 元数据栏
              _buildMetaBar(),
              const Divider(height: 1, color: dividerColor),
              // 底部工具栏
              _buildToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String dateLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 22, color: Color(0xFF8E8E93)),
            onPressed: () async {
              await _saveDraft();
              if (mounted) Navigator.pop(context);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked
                  ? const Color(0xFFFFB300)
                  : const Color(0xFF8E8E93),
              size: 22,
            ),
            onPressed: () =>
                setState(() => _isBookmarked = !_isBookmarked),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._imagePaths.asMap().entries.map((e) => _buildImageTile(e.key)),
          if (_imagePaths.length < 3)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF3A3A3C), width: 1),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined,
                    color: Color(0xFF636366), size: 28),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_imagePaths[index]),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => Container(
              width: 80,
              height: 80,
              color: const Color(0xFF2C2C2E),
              child: const Icon(Icons.broken_image,
                  color: Color(0xFF636366)),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2C2C2E),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickWeather,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny_outlined,
                    size: 16, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Text(
                  _weather ?? '天气',
                  style: TextStyle(
                    fontSize: 13,
                    color: _weather != null
                        ? const Color(0xFFAEAEB2)
                        : const Color(0xFF636366),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _pickLocation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Text(
                  _location ?? '位置',
                  style: TextStyle(
                    fontSize: 13,
                    color: _location != null
                        ? const Color(0xFFAEAEB2)
                        : const Color(0xFF636366),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$_wordCount字',
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF636366)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF1C1C1E),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuillToolbarToggleStyleButton(
                controller: _quillController,
                attribute: Attribute.bold,
                options: const QuillToolbarToggleStyleButtonOptions(
                  iconData: Icons.format_bold,
                  iconSize: 20,
                ),
              ),
              QuillToolbarToggleStyleButton(
                controller: _quillController,
                attribute: Attribute.blockQuote,
                options: const QuillToolbarToggleStyleButtonOptions(
                  iconData: Icons.format_quote,
                  iconSize: 20,
                ),
              ),
              QuillToolbarToggleStyleButton(
                controller: _quillController,
                attribute: Attribute.ul,
                options: const QuillToolbarToggleStyleButtonOptions(
                  iconData: Icons.format_list_bulleted,
                  iconSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.undo, size: 20,
                    color: Color(0xFF8E8E93)),
                onPressed: () {
                  _quillController.undo();
                },
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20,
                    color: Color(0xFF8E8E93)),
                onPressed: () {
                  _quillController.redo();
                },
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? '保存中...' : '完成',
              style: TextStyle(
                color: _isSaving
                    ? const Color(0xFF636366)
                    : const Color(0xFF4CAF50),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
