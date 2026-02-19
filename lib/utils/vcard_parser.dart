import 'dart:convert';

/// Parses vCard (.vcf) file content into a list of contact maps.
/// Supports vCard 2.1, 3.0, and 4.0 formats.
class VcardParser {
  /// Parses raw vCard text and returns a list of contact maps.
  /// Each map contains keys: 'name', 'phone', 'email', 'gender'.
  static List<Map<String, dynamic>> parse(String content) {
    final contacts = <Map<String, dynamic>>[];
    
    // Step 1: Handle QUOTED-PRINTABLE soft line breaks FIRST
    // Soft line break is '=' followed by CRLF or LF (optionally followed by space/tab)
    var processed = content
        .replaceAll(RegExp(r'=\r\n[ \t]?'), '')
        .replaceAll(RegExp(r'=\n[ \t]?'), '');
    
    // Step 2: Handle standard vCard line folding (lines starting with space/tab)
    processed = processed
        .replaceAll('\r\n ', '')
        .replaceAll('\r\n\t', '')
        .replaceAll('\n ', '')
        .replaceAll('\n\t', '');
    
    final lines = processed.split(RegExp(r'\r?\n'));

    Map<String, dynamic>? current;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toUpperCase() == 'BEGIN:VCARD') {
        current = {
          'name': '',
          'phone': <String>[],
          'email': '',
          'gender': null,
        };
      } else if (trimmed.toUpperCase() == 'END:VCARD') {
        if (current != null && (current['name'] as String).isNotEmpty) {
          contacts.add(current);
        }
        current = null;
      } else if (current != null) {
        _parseLine(trimmed, current);
      }
    }
    return contacts;
  }

  static void _parseLine(String line, Map<String, dynamic> contact) {
    final upperLine = line.toUpperCase();

    // FN (Formatted Name) - preferred over N
    if (upperLine.startsWith('FN')) {
      final value = _extractAndDecodeValue(line);
      if (value.isNotEmpty) {
        contact['name'] = value;
      }
    }
    // N (Name) - fallback if FN not set
    else if (upperLine.startsWith('N:') || upperLine.startsWith('N;')) {
      if ((contact['name'] as String).isEmpty) {
        final value = _extractAndDecodeValue(line);
        // N format: LastName;FirstName;MiddleName;Prefix;Suffix
        final parts = value.split(';').where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          // Combine last + first name
          if (parts.length >= 2) {
            contact['name'] = '${parts[0]}${parts[1]}';
          } else {
            contact['name'] = parts[0];
          }
        }
      }
    }
    // TEL (Phone)
    else if (upperLine.startsWith('TEL')) {
      final value = _extractAndDecodeValue(line);
      if (value.isNotEmpty) {
        final phones = contact['phone'] as List<String>;
        final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleaned.isNotEmpty && !phones.contains(cleaned)) {
          phones.add(cleaned);
        }
      }
    }
    // EMAIL
    else if (upperLine.startsWith('EMAIL')) {
      final value = _extractAndDecodeValue(line);
      if (value.isNotEmpty && (contact['email'] as String).isEmpty) {
        contact['email'] = value;
      }
    }
    // GENDER (vCard 4.0)
    else if (upperLine.startsWith('GENDER')) {
      final value = _extractAndDecodeValue(line).toUpperCase();
      if (value.startsWith('M')) {
        contact['gender'] = '男';
      } else if (value.startsWith('F')) {
        contact['gender'] = '女';
      }
    }
  }

  /// Extracts the value part after the colon and decodes if necessary.
  static String _extractAndDecodeValue(String line) {
    final colonIndex = line.indexOf(':');
    if (colonIndex < 0) return '';
    
    final params = line.substring(0, colonIndex).toUpperCase();
    final rawValue = line.substring(colonIndex + 1);
    
    // Check if QUOTED-PRINTABLE encoding is used
    if (params.contains('ENCODING=QUOTED-PRINTABLE') || 
        params.contains('QUOTED-PRINTABLE')) {
      // Determine charset (default to UTF-8)
      final isUtf8 = params.contains('CHARSET=UTF-8') || 
                     params.contains('UTF-8') ||
                     !params.contains('CHARSET=');
      return _decodeQuotedPrintable(rawValue, isUtf8);
    }
    
    return rawValue.trim();
  }

  /// Decodes Quoted-Printable encoded string.
  static String _decodeQuotedPrintable(String input, bool isUtf8) {
    final bytes = <int>[];
    int i = 0;
    
    while (i < input.length) {
      if (input[i] == '=') {
        // Check if there are at least 2 more characters
        if (i + 2 < input.length) {
          final hex = input.substring(i + 1, i + 3);
          // Check if it's a valid hex pair
          if (RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(hex)) {
            bytes.add(int.parse(hex, radix: 16));
            i += 3;
            continue;
          }
        }
        // Skip standalone '=' (likely leftover from soft break)
        i++;
        continue;
      }
      // Regular character
      bytes.add(input.codeUnitAt(i));
      i++;
    }
    
    try {
      if (isUtf8) {
        return utf8.decode(bytes, allowMalformed: true);
      } else {
        // Fallback to Latin-1
        return latin1.decode(bytes);
      }
    } catch (e) {
      // If decoding fails, return original string
      return input.trim();
    }
  }
}
