import 'package:flutter/material.dart';
import '../database/tag_dao.dart';
import '../models/tag.dart';

class EditTagPage extends StatefulWidget {
  final Tag? tag; // null = create mode, non-null = edit mode

  const EditTagPage({super.key, this.tag});

  @override
  State<EditTagPage> createState() => _EditTagPageState();
}

class _EditTagPageState extends State<EditTagPage> {
  late TextEditingController _controller;
  bool get isEdit => widget.tag != null;
  static const int maxLength = 15;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tag?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      _showSnackBar('请输入标签名称');
      return;
    }
    if (name.length > maxLength) {
      _showSnackBar('标签名称不能超过$maxLength个字符');
      return;
    }

    // Check for duplicates
    final existing = await TagDao.getByName(name);
    if (existing != null && existing.id != widget.tag?.id) {
      _showSnackBar('标签名称已存在');
      return;
    }

    if (isEdit) {
      final updated = widget.tag!.copyWith(name: name);
      await TagDao.update(updated);
      if (mounted) Navigator.pop(context, updated);
    } else {
      final tag = Tag(name: name);
      final id = await TagDao.insert(tag);
      final newTag = tag.copyWith(id: id);
      if (mounted) Navigator.pop(context, newTag);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? '编辑标签' : '新建标签',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '标签名称',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLength: maxLength,
                    decoration: InputDecoration(
                      hintText: '填写标签名称',
                      hintStyle: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 15,
                      ),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF333333)),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_controller.text.length}/$maxLength',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? '保存' : '确定',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
