import 'package:flutter/material.dart';

class SpiritAvatar extends StatelessWidget {
  final String? avatarPath;
  final double size;
  final VoidCallback? onTap;

  const SpiritAvatar({
    super.key,
    this.avatarPath,
    this.size = 56,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: ClipOval(
          child: avatarPath != null && avatarPath!.isNotEmpty
              ? Image.asset(
                  avatarPath!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _placeholder(),
                )
              : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.pets,
      size: size * 0.5,
      color: Colors.grey[400],
    );
  }
}
