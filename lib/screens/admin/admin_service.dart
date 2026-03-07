import 'package:cloud_firestore/cloud_firestore.dart';

enum SermonCategory { sunday, wednesday }

enum MessageType { series, single }

class Episode {
  final String id;
  final int episodeNumber;
  final String title;
  final String speaker;
  final DateTime date;
  final String duration;
  final String audioUrl;
  final String description;
  final String? imageUrl;
  final int playCount;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.speaker,
    required this.date,
    required this.duration,
    required this.audioUrl,
    required this.description,
    this.imageUrl,
    this.playCount = 0,
  });

  // Helper for safe date parsing across Firestore and Local Storage
  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  Episode copyWith({
    String? id,
    int? episodeNumber,
    String? title,
    String? speaker,
    DateTime? date,
    String? duration,
    String? audioUrl,
    String? description,
    String? imageUrl,
    int? playCount,
  }) {
    return Episode(
      id: id ?? this.id,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      playCount: playCount ?? this.playCount,
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? '',
      episodeNumber:
          int.tryParse(json['episodeNumber']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      speaker: json['speaker'] ?? '',
      date: _parseDate(json['date']),
      duration: json['duration'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      playCount: json['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episodeNumber': episodeNumber,
      'title': title,
      'speaker': speaker,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'audioUrl': audioUrl,
      'description': description,
      'imageUrl': imageUrl,
      'playCount': playCount,
    };
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'episodeNumber': episodeNumber,
      'title': title,
      'speaker': speaker,
      'date': date.toIso8601String(),
      'duration': duration,
      'audioUrl': audioUrl,
      'description': description,
      'imageUrl': imageUrl,
      'playCount': playCount,
    };
  }
}

class Sermon {
  final String id;
  final String title;
  final String speaker;
  final DateTime date;
  final String duration;
  final SermonCategory category;
  final MessageType messageType;
  final String audioUrl;
  final String description;
  final String? imageUrl;
  final List<Episode> episodes;
  final String? seriesTitle;
  final int playCount;
  final DateTime? createdAt;

  int get totalEpisodes => episodes.length;
  bool get isSeries => messageType == MessageType.series;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    required this.date,
    required this.duration,
    required this.category,
    required this.messageType,
    required this.audioUrl,
    required this.description,
    this.imageUrl,
    this.episodes = const [],
    this.seriesTitle,
    this.playCount = 0,
    this.createdAt,
  });

  // copyWith method to fix AdminService errors
  Sermon copyWith({
    String? id,
    String? title,
    String? speaker,
    DateTime? date,
    String? duration,
    SermonCategory? category,
    MessageType? messageType,
    String? audioUrl,
    String? description,
    String? imageUrl,
    List<Episode>? episodes,
    String? seriesTitle,
    int? playCount,
    DateTime? createdAt,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      messageType: messageType ?? this.messageType,
      audioUrl: audioUrl ?? this.audioUrl,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      episodes: episodes ?? this.episodes,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      playCount: playCount ?? this.playCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Sermon.fromFirestore(Map<String, dynamic> json, String docId) {
    final List<dynamic> episodesData = json['episodes'] as List? ?? [];
    final typeStr = json['messageType']?.toString().toLowerCase() ?? '';

    return Sermon(
      id: docId,
      title: json['title'] ?? '',
      speaker: json['speaker'] ?? '',
      date: Episode._parseDate(json['date']),
      duration: json['duration'] ?? '',
      category: json['category']?.toString().toLowerCase() == 'wednesday'
          ? SermonCategory.wednesday
          : SermonCategory.sunday,
      messageType:
          typeStr == 'series' ? MessageType.series : MessageType.single,
      audioUrl: json['audioUrl'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      seriesTitle: json['seriesTitle'],
      playCount: json['playCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? Episode._parseDate(json['createdAt'])
          : null,
      episodes: episodesData
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'speaker': speaker,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'category': category.name,
      'messageType': messageType.name,
      'audioUrl': audioUrl,
      'description': description,
      'imageUrl': imageUrl,
      'episodes': episodes.map((e) => e.toMap()).toList(),
      'playCount': playCount,
      'seriesTitle': seriesTitle,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'speaker': speaker,
      'date': date.toIso8601String(),
      'duration': duration,
      'category': category.name,
      'messageType': messageType.name,
      'audioUrl': audioUrl,
      'description': description,
      'imageUrl': imageUrl,
      'seriesTitle': seriesTitle,
      'playCount': playCount,
      'createdAt': createdAt?.toIso8601String(),
      'episodes': episodes.map((e) => e.toStorageMap()).toList(),
    };
  }

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      speaker: json['speaker'] ?? '',
      date: Episode._parseDate(json['date']),
      duration: json['duration'] ?? '',
      category: json['category'] == 'wednesday'
          ? SermonCategory.wednesday
          : SermonCategory.sunday,
      messageType: json['messageType'] == 'series'
          ? MessageType.series
          : MessageType.single,
      audioUrl: json['audioUrl'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      seriesTitle: json['seriesTitle'],
      playCount: json['playCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? Episode._parseDate(json['createdAt'])
          : null,
      episodes: (json['episodes'] as List?)
              ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
