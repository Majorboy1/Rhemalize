import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhemalize/models/testimony.dart';

void main() {
  group('Testimony model', () {
    test('fromFirestore parses the stored testimony shape', () {
      final timestamp = Timestamp.fromDate(DateTime(2024, 5, 16));
      final data = {
        'title': 'Grace carried me through',
        'speaker': 'Jane Doe',
        'date': timestamp,
        'duration': '03:42',
        'audioUrl': 'https://example.com/testimony.mp3',
        'description': 'A testimony about healing and faith.',
        'imageUrl': 'https://example.com/cover.jpg',
        'playCount': 12,
      };

      final testimony = Testimony.fromFirestore(data, 'abc123');

      expect(testimony.id, 'abc123');
      expect(testimony.title, 'Grace carried me through');
      expect(testimony.speaker, 'Jane Doe');
      expect(testimony.audioUrl, 'https://example.com/testimony.mp3');
      expect(testimony.duration, '03:42');
      expect(testimony.playCount, 12);
    });

    test('toFirestore writes a safe Firestore payload', () {
      final testimony = Testimony(
        id: 'a1',
        title: 'Saved by grace',
        speaker: 'John Doe',
        date: DateTime(2024, 5, 20),
        duration: '02:10',
        audioUrl: 'https://example.com/audio.mp3',
        description: 'Short testimony',
        imageUrl: 'https://example.com/cover.png',
        playCount: 3,
      );

      final map = testimony.toFirestore();

      expect(map['title'], 'Saved by grace');
      expect(map['speaker'], 'John Doe');
      expect(map['audioUrl'], 'https://example.com/audio.mp3');
      expect(map['playCount'], 3);
      expect(map['date'], isA<Timestamp>());
    });
  });
}
