import 'package:flutter/material.dart';

class WeatherPicker extends StatelessWidget {
  final String? currentWeather;

  const WeatherPicker({super.key, this.currentWeather});

  static const List<Map<String, String>> weatherOptions = [
    {'icon': '\u2600\ufe0f', 'label': '\u6674'},
    {'icon': '\u26c5', 'label': '\u591a\u4e91'},
    {'icon': '\u2601\ufe0f', 'label': '\u9634'},
    {'icon': '\ud83c\udf27\ufe0f', 'label': '\u5c0f\u96e8'},
    {'icon': '\u26c8\ufe0f', 'label': '\u5927\u96e8'},
    {'icon': '\u2744\ufe0f', 'label': '\u96ea'},
    {'icon': '\ud83c\udf2b\ufe0f', 'label': '\u96fe'},
  ];

  static Future<String?> show(BuildContext context, {String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => WeatherPicker(currentWeather: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\u9009\u62e9\u5929\u6c14',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: weatherOptions.map((opt) {
                final isSelected = currentWeather == opt['label'];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, opt['label']),
                  child: Container(
                    width: 72,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50).withAlpha(26)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF4CAF50))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(opt['icon']!,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          opt['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF666666),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (currentWeather != null)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: const Text(
                    '\u6e05\u9664\u5929\u6c14',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
