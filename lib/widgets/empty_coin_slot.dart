import 'package:flutter/material.dart';

/// 空槽位Widget - 用于添加新人员到部门
class EmptyCoinSlot extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const EmptyCoinSlot({
    super.key,
    this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 虚线圆框
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withAlpha(100),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: Colors.grey.withAlpha(150),
                strokeWidth: 2,
                dashWidth: 6,
                dashSpace: 4,
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey.withAlpha(150),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 占位文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: const Text(
              '添加',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 虚线圆形绘制器
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final dashAngle = (dashWidth / circumference) * 2 * 3.14159;
    final spaceAngle = (dashSpace / circumference) * 2 * 3.14159;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + spaceAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
