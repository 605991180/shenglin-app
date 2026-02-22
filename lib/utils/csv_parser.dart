/// CSV解析器（零依赖实现）
/// 支持UTF-8编码，处理引号包裹字段、换行、转义引号
class CsvParser {
  /// 解析CSV文本，返回表头和数据行
  static ({List<String> headers, List<Map<String, String>> rows}) parse(
      String csvText) {
    // 移除各种可能的BOM和不可见字符
    csvText = _removeBom(csvText);

    final lines = _splitLines(csvText);
    if (lines.isEmpty) {
      return (headers: [], rows: []);
    }

    // 解析表头并清理不可见字符
    final headers = _parseLine(lines.first)
        .map((h) => _cleanString(h))
        .toList();
    final rows = <Map<String, String>>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final values = _parseLine(line);
      final row = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        final key = headers[j];
        final value = j < values.length ? _cleanString(values[j]) : '';
        row[key] = value;
      }
      rows.add(row);
    }

    return (headers: headers, rows: rows);
  }

  /// 移除BOM和其他不可见前缀字符
  static String _removeBom(String text) {
    if (text.isEmpty) return text;
    
    // UTF-8 BOM: \uFEFF
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    
    // 有些情况下BOM可能被错误解码为多个字符 (ï»¿)
    if (text.startsWith('\u00EF\u00BB\u00BF')) {
      text = text.substring(3);
    }
    
    // 移除开头的所有不可见控制字符
    while (text.isNotEmpty) {
      final firstChar = text.codeUnitAt(0);
      // 移除控制字符(0-31)和BOM(0xFEFF)和零宽字符等
      if (firstChar < 32 || 
          firstChar == 0xFEFF || 
          firstChar == 0x200B || // 零宽空格
          firstChar == 0x200C || // 零宽非连接符
          firstChar == 0x200D) { // 零宽连接符
        text = text.substring(1);
      } else {
        break;
      }
    }
    
    return text;
  }

  /// 清理字符串中的不可见字符
  static String _cleanString(String s) {
    // 先trim
    s = s.trim();
    
    // 移除开头和结尾的不可见字符
    while (s.isNotEmpty) {
      final firstChar = s.codeUnitAt(0);
      if (firstChar < 32 || firstChar == 0xFEFF || firstChar == 0x200B) {
        s = s.substring(1);
      } else {
        break;
      }
    }
    
    while (s.isNotEmpty) {
      final lastChar = s.codeUnitAt(s.length - 1);
      if (lastChar < 32 || lastChar == 0xFEFF || lastChar == 0x200B) {
        s = s.substring(0, s.length - 1);
      } else {
        break;
      }
    }
    
    return s;
  }

  /// 将CSV文本分割为行（处理引号内的换行）
  static List<String> _splitLines(String text) {
    final lines = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '"') {
        // 检查是否为转义引号
        if (inQuotes && i + 1 < text.length && text[i + 1] == '"') {
          buffer.write('""');
          i++;
        } else {
          inQuotes = !inQuotes;
          buffer.write(char);
        }
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        // 处理\r\n
        if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
          i++;
        }
        if (buffer.isNotEmpty) {
          lines.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    // 最后一行
    if (buffer.isNotEmpty) {
      lines.add(buffer.toString());
    }

    return lines;
  }

  /// 解析单行CSV，处理引号包裹字段
  static List<String> _parseLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        // 检查是否为转义引号（两个连续引号表示一个引号字符）
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // 最后一个字段
    fields.add(buffer.toString());

    return fields;
  }

  /// 获取指定列的值，支持多个可能的列名
  static String getValue(
      Map<String, String> row, List<String> possibleNames, String defaultValue) {
    for (final name in possibleNames) {
      if (row.containsKey(name) && row[name]!.isNotEmpty) {
        return row[name]!;
      }
    }
    return defaultValue;
  }

  /// 解析分号分隔的列表字段
  static List<String> parseListField(String value) {
    if (value.isEmpty) return [];
    return value
        .split(RegExp(r'[;；]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 解析整数
  static int? parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }
}
