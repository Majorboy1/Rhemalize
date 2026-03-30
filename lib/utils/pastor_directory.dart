import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_constants.dart';

class PastorDirectory {
  static const List<String> _pinnedSpeakerNames = [
    AppConstants.seniorPastorName,
    'Ma Judith Elliot',
  ];

  static List<String> get fallbackSpeakerNames =>
      List<String>.unmodifiable(_mergeSpeakerNames(const []));

  static Future<List<String>> loadSpeakerNames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('pastors').get();
      final names = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty);

      return _mergeSpeakerNames(names);
    } catch (_) {
      return fallbackSpeakerNames;
    }
  }

  static List<String> _mergeSpeakerNames(Iterable<String> names) {
    final orderedNames = <String>[];
    final seen = <String>{};

    void addName(String value) {
      final trimmed = value.trim();
      final normalized = _normalize(trimmed);
      if (normalized.isEmpty || !seen.add(normalized)) return;
      orderedNames.add(trimmed);
    }

    for (final name in _pinnedSpeakerNames) {
      addName(name);
    }
    for (final name in names) {
      addName(name);
    }

    orderedNames.sort((a, b) {
      final priorityCompare = _sortPriority(a).compareTo(_sortPriority(b));
      if (priorityCompare != 0) return priorityCompare;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return orderedNames;
  }

  static int _sortPriority(String name) {
    final normalized = _normalize(name);
    if (normalized.contains('bright elliot')) return 0;
    if (normalized.contains('judith elliot')) return 1;
    return 2;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
  }
}
