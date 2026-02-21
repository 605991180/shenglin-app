import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';

class DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容预览
            Text(
              _getPlainText(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            // 图片缩略图
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildImageRow(),
            ],
            const SizedBox(height: 10),
            // 底部元数据
            _buildMetaRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageRow() {
    return SizedBox(
      height: 60,
      child: Row(
        children: entry.imagePaths.take(3).map((path) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(path),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(Icons.image,
                      color: Color(0xFFCCCCCC), size: 24),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetaRow() {
    final time = DateFormat('HH:mm').format(entry.date);
    final parts = <String>[time];
    if (entry.weather != null && entry.weather!.isNotEmpty) {
      parts.add(entry.weather!);
    }
    if (entry.location != null && entry.location!.isNotEmpty) {
      parts.add(entry.location!);
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join(' \u00b7 '),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ),
        if (entry.isBookmarked)
          const Icon(Icons.bookmark, color: Color(0xFFFFB300), size: 16),
      ],
    );
  }

  String _getPlainText() {
    final content = entry.content;
    if (content.isEmpty) return '(无内容)';
    // Content is now plain text
    final text = content.trim();
    return text.isNotEmpty ? text : '(无内容)';
  }
}
