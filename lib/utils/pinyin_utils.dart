import 'package:lpinyin/lpinyin.dart';

class PinyinUtils {
  static String getPinyin(String chinese) {
    if (chinese.isEmpty) return '';
    return PinyinHelper.getPinyinE(chinese, separator: '').toLowerCase();
  }

  static String getFirstLetter(String chinese) {
    if (chinese.isEmpty) return '#';
    final pinyin = PinyinHelper.getFirstWordPinyin(chinese);
    if (pinyin.isEmpty) return '#';
    final first = pinyin[0].toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }
}
