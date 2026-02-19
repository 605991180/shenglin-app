import 'package:flutter/material.dart';

class TagListItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onCheckTap;

  const TagListItem({
    super.key,
    required this.name,
    required this.isSelected,
    this.count,
    this.onTap,
    this.onCheckTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? onCheckTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onCheckTap,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            if (count != null)
              Text(
                '($count)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
