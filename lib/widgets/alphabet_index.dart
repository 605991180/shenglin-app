import 'package:flutter/material.dart';

class AlphabetIndex extends StatelessWidget {
  final List<String> letters;
  final String? activeLetter;
  final ValueChanged<String> onLetterTap;
  final VoidCallback? onTopTap;

  const AlphabetIndex({
    super.key,
    required this.letters,
    this.activeLetter,
    required this.onLetterTap,
    this.onTopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onTopTap != null)
            _buildItem('↑', false, () => onTopTap!()),
          ...letters.map((letter) {
            final isActive = letter == activeLetter;
            return _buildItem(letter, isActive, () => onLetterTap(letter));
          }),
        ],
      ),
    );
  }

  Widget _buildItem(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 20,
        height: 18,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }
}
