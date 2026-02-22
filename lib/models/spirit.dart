import 'dart:convert';
import 'tag.dart';

class Spirit {
  final String id;
  final String name;
  final String? avatar;
  final String? gender;
  final int? age;
  final String? ethnicity;
  final String? idNumber;
  final String? identity;
  final String? identityLevel;
  final String? primaryRelation;
  final String? preference;
  final String? personality;
  final String? affinity;
  final List<String> phone;
  final String? memo;
  final List<String> photos;
  final List<String> typeLabels;
  final DateTime createdAt;
  final String? pinyin;
  final String? firstLetter;
  List<Tag> tags;

  Spirit({
    required this.id,
    required this.name,
    this.avatar,
    this.gender,
    this.age,
    this.ethnicity,
    this.idNumber,
    this.identity,
    this.identityLevel,
    this.primaryRelation,
    this.preference,
    this.personality,
    this.affinity,
    List<String>? phone,
    this.memo,
    List<String>? photos,
    List<String>? typeLabels,
    DateTime? createdAt,
    this.pinyin,
    this.firstLetter,
    List<Tag>? tags,
  })  : phone = phone ?? [],
        photos = photos ?? [],
        typeLabels = typeLabels ?? [],
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'age': age,
      'ethnicity': ethnicity,
      'id_number': idNumber,
      'identity': identity,
      'identity_level': identityLevel,
      'primary_relation': primaryRelation,
      'preference': preference,
      'personality': personality,
      'affinity': affinity,
      'phone': jsonEncode(phone),
      'memo': memo,
      'photos': jsonEncode(photos),
      'type_labels': jsonEncode(typeLabels),
      'created_at': createdAt.millisecondsSinceEpoch,
      'pinyin': pinyin,
      'first_letter': firstLetter,
    };
  }

  factory Spirit.fromMap(Map<String, dynamic> map) {
    return Spirit(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String?,
      gender: map['gender'] as String?,
      age: map['age'] as int?,
      ethnicity: map['ethnicity'] as String?,
      idNumber: map['id_number'] as String?,
      identity: map['identity'] as String?,
      identityLevel: map['identity_level'] as String?,
      primaryRelation: map['primary_relation'] as String?,
      preference: map['preference'] as String?,
      personality: map['personality'] as String?,
      affinity: map['affinity'] as String?,
      phone: _decodeJsonList(map['phone']),
      memo: map['memo'] as String?,
      photos: _decodeJsonList(map['photos']),
      typeLabels: _decodeJsonList(map['type_labels']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      pinyin: map['pinyin'] as String?,
      firstLetter: map['first_letter'] as String?,
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

  Spirit copyWith({
    String? id,
    String? name,
    String? avatar,
    String? gender,
    int? age,
    String? ethnicity,
    String? idNumber,
    String? identity,
    String? identityLevel,
    String? primaryRelation,
    String? preference,
    String? personality,
    String? affinity,
    List<String>? phone,
    String? memo,
    List<String>? photos,
    List<String>? typeLabels,
    String? pinyin,
    String? firstLetter,
    List<Tag>? tags,
  }) {
    return Spirit(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      ethnicity: ethnicity ?? this.ethnicity,
      idNumber: idNumber ?? this.idNumber,
      identity: identity ?? this.identity,
      identityLevel: identityLevel ?? this.identityLevel,
      primaryRelation: primaryRelation ?? this.primaryRelation,
      preference: preference ?? this.preference,
      personality: personality ?? this.personality,
      affinity: affinity ?? this.affinity,
      phone: phone ?? List.from(this.phone),
      memo: memo ?? this.memo,
      photos: photos ?? List.from(this.photos),
      typeLabels: typeLabels ?? List.from(this.typeLabels),
      createdAt: createdAt,
      pinyin: pinyin ?? this.pinyin,
      firstLetter: firstLetter ?? this.firstLetter,
      tags: tags ?? List.from(this.tags),
    );
  }
}
