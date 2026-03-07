class Episode {
  final String id;
  final String title;
  final String pastor;
  final String audioUrl;
  final int duration;
  final DateTime date;

  Episode({
    required this.id,
    required this.title,
    required this.pastor,
    required this.audioUrl,
    required this.duration,
    required this.date,
  });

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')} hr';
    }
    return '$minutes min';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pastor': pastor,
        'audioUrl': audioUrl,
        'duration': duration,
        'date': date.toIso8601String(),
      };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'],
        title: json['title'],
        pastor: json['pastor'],
        audioUrl: json['audioUrl'],
        duration: json['duration'],
        date: DateTime.parse(json['date']),
      );
}
