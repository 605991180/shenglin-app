import 'dart:convert';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String content; // Quill JSON string
  final List<String> imagePaths;
  final String? weather;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? device;
  final int wordCount;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    this.content = '',
    List<String>? imagePaths,
    this.weather,
    this.location,
    this.latitude,
    this.longitude,
    this.device,
    this.wordCount = 0,
    this.isBookmarked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : imagePaths = imagePaths ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'content': content,
      'image_paths': jsonEncode(imagePaths),
      'weather': weather,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'device': device,
      'word_count': wordCount,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      content: (map['content'] as String?) ?? '',
      imagePaths: _decodeJsonList(map['image_paths']),
      weather: map['weather'] as String?,
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      device: map['device'] as String?,
      wordCount: (map['word_count'] as int?) ?? 0,
      isBookmarked: (map['is_bookmarked'] as int?) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  static List<String> _decodeJsonList(dynamic value) {
    if (value == null || value == '') return [];
    try {
      final list = jsonDecode(value as String);
      return (list as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    List<String>? imagePaths,
    String? weather,
    String? location,
    double? latitude,
    double? longitude,
    String? device,
    int? wordCount,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      imagePaths: imagePaths ?? List.from(this.imagePaths),
      weather: weather ?? this.weather,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      device: device ?? this.device,
      wordCount: wordCount ?? this.wordCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DiaryDraft {
  final String id;
  final String? diaryId;
  final String content;
  final List<String> imagePaths;
  final DateTime savedAt;

  DiaryDraft({
    required this.id,
    this.diaryId,
    this.content = '',
    List<String>? imagePaths,
    DateTime? savedAt,
  })  : imagePaths = imagePaths ?? [],
        savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diary_id': diaryId,
      'content': content,
      'image_paths': jsonEncode(imagePaths),
      'saved_at': savedAt.millisecondsSinceEpoch,
    };
  }

  factory DiaryDraft.fromMap(Map<String, dynamic> map) {
    return DiaryDraft(
      id: map['id'] as String,
      diaryId: map['diary_id'] as String?,
      content: (map['content'] as String?) ?? '',
      imagePaths: _decodeJsonList(map['image_paths']),
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
    );
  }

  static List<String> _decodeJsonList(dynamic value) {
    if (value == null || value == '') return [];
    try {
      final list = jsonDecode(value as String);
      return (list as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
