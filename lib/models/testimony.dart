import 'package:cloud_firestore/cloud_firestore.dart';

class Testimony {
  final String id;
  final String title;
  final String speaker;
  final DateTime date;
  final String duration;
  final String audioUrl;
  final String description;
  final String? imageUrl;
  final int playCount;
  final DateTime? createdAt;

  const Testimony({
    required this.id,
    required this.title,
    required this.speaker,
    required this.date,
    required this.duration,
    required this.audioUrl,
    required this.description,
    this.imageUrl,
    this.playCount = 0,
    this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Testimony copyWith({
    String? id,
    String? title,
    String? speaker,
    DateTime? date,
    String? duration,
    String? audioUrl,
    String? description,
    String? imageUrl,
    int? playCount,
    DateTime? createdAt,
  }) {
    return Testimony(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      playCount: playCount ?? this.playCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Testimony.fromFirestore(Map<String, dynamic> json, String docId) {
    return Testimony(
      id: docId,
      title: json['title'] ?? '',
      speaker: json['speaker'] ?? '',
      date: _parseDate(json['date']),
      duration: json['duration'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      playCount: json['playCount'] ?? 0,
      createdAt:
          json['createdAt'] != null ? _parseDate(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'speaker': speaker,
        'date': Timestamp.fromDate(date),
        'duration': duration,
        'audioUrl': audioUrl,
        'description': description,
        'imageUrl': imageUrl,
        'playCount': playCount,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
