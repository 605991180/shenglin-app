import 'package:flutter/material.dart';
import '../models/refined_field_models.dart';

/// 硬币Widget - 显示精养田中的人员
class OfficialCoin extends StatelessWidget {
  final RefinedPerson person;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;

  const OfficialCoin({
    super.key,
    required this.person,
    this.onTap,
    this.onLongPress,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 硬币图片
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                person.level.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _getFallbackColor(person.level),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 姓名标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _truncateName(person.name),
              style: TextStyle(
                fontSize: 10,
                color: Colors.amber[100],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateName(String name) {
    if (name.length <= 4) return name;
    return '${name.substring(0, 3)}…';
  }

  Color _getFallbackColor(CoinLevel level) {
    switch (level) {
      case CoinLevel.gold:
        return const Color(0xFFFFD700);
      case CoinLevel.silver:
        return const Color(0xFFC0C0C0);
      case CoinLevel.bronze:
        return const Color(0xFFCD7F32);
      case CoinLevel.iron:
        return const Color(0xFF696969);
    }
  }
}
