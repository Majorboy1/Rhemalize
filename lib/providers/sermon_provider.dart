import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/duration_helper.dart';

class SermonProvider with ChangeNotifier implements PlaybackDataDelegate {
  List<Sermon> _sermons = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _sermonSubscription;

  List<Sermon> get sermons => _sermons;
  bool get isLoading => _isLoading;

  List<Sermon> get oneTimeMessages =>
      _sermons.where((s) => s.messageType == MessageType.single).toList();

  List<Sermon> get seriesMessages =>
      _sermons.where((s) => s.messageType == MessageType.series).toList();

  SermonProvider() {
    _loadCachedSermons();
    _listenToSermons();
  }

  Future<void> _loadCachedSermons() async {
    final cachedData = await StorageService().getSavedSermons();
    if (cachedData.isNotEmpty) {
      _sermons = cachedData;
      _isLoading = false;
      notifyListeners();
      // Start resolving missing durations immediately from cached data
      _resolveAllMissingDurations();
    }
  }

  void _listenToSermons() {
    _sermonSubscription?.cancel();
    _sermonSubscription = FirebaseFirestore.instance
        .collection('sermons')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _sermons = snapshot.docs.map((doc) {
        // Safe mapping using our updated fromFirestore model logic
        return Sermon.fromFirestore(doc.data(), doc.id);
      }).toList();
      _isLoading = false;

      // Update local cache
      StorageService().saveSermons(_sermons);
      notifyListeners();

      // Immediately resolve ALL missing durations in parallel
      _resolveAllMissingDurations();

      // Also trigger one-time Cloud Function backfill
      if (!_backfillStarted && _sermons.isNotEmpty) {
        _backfillStarted = true;
        backfillDurations();
      }
    }, onError: (error) {
      AppLogger.debug("Firestore Listener Error", error);
      _isLoading = false;
      notifyListeners();
    });
  }

  // ================= DURATION RESOLUTION =================

  /// Cache of durations resolved from audio files.
  /// Key = sermon/episode ID, Value = formatted duration string.
  final Map<String, String> _durationCache = {};

  bool _backfillStarted = false;

  /// Returns the display duration for a [Sermon].
  /// If stored value is "0:00", returns cached value (or "0:00" if not yet resolved).
  String getSermonDuration(Sermon sermon) {
    if (sermon.duration.isNotEmpty && sermon.duration != '0:00') {
      return sermon.duration;
    }
    return _durationCache[sermon.id] ?? '0:00';
  }

  /// Returns the display duration for an [Episode].
  String getEpisodeDuration(Episode episode) {
    if (episode.duration.isNotEmpty && episode.duration != '0:00') {
      return episode.duration;
    }
    return _durationCache[episode.id] ?? '0:00';
  }

  /// Resolves all missing durations immediately after sermons load.
  /// Runs in parallel — each sermon/episode resolves independently.
  void _resolveAllMissingDurations() {
    for (final sermon in _sermons) {
      if ((sermon.duration.isEmpty || sermon.duration == '0:00') &&
          sermon.audioUrl.isNotEmpty &&
          !_durationCache.containsKey(sermon.id)) {
        _resolveAndCache(sermon.id, sermon.audioUrl);
      }
      for (final episode in sermon.episodes) {
        if ((episode.duration.isEmpty || episode.duration == '0:00') &&
            episode.audioUrl.isNotEmpty &&
            !_durationCache.containsKey(episode.id)) {
          _resolveAndCache(episode.id, episode.audioUrl);
        }
      }
    }
  }

  /// Kicks off async resolution for one sermon/episode.
  void _resolveAndCache(String id, String audioUrl) {
    unawaited(_doResolveAndCache(id, audioUrl));
  }

  Future<void> _doResolveAndCache(String id, String audioUrl) async {
    try {
      final dur = await extractDurationFromUrl(audioUrl);
      if (dur != null && dur.inMilliseconds > 0) {
        _durationCache[id] = formatDuration(dur);
        debugPrint('[Duration] Resolved $id → ${formatDuration(dur)}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Duration] Failed to resolve $id: $e');
    }
  }

  /// Backfills durations for all existing sermons by extracting duration
  /// from each audio URL. Runs in parallel per sermon/episode.
  Future<Map<String, dynamic>> backfillDurations({
    void Function(int, int)? onProgress,
  }) async {
    // Client-side extraction using platform-specific audio API
    final Map<String, String> sermonsToFix = {};
    final Map<String, List<Map<String, dynamic>>> episodeFixes = {};

    for (final sermon in _sermons) {
      if (sermon.duration.isEmpty || sermon.duration == '0:00') {
        if (sermon.audioUrl.isNotEmpty) {
          sermonsToFix[sermon.id] = sermon.audioUrl;
        }
      }
      for (final episode in sermon.episodes) {
        if (episode.duration.isEmpty || episode.duration == '0:00') {
          if (episode.audioUrl.isNotEmpty) {
            episodeFixes.putIfAbsent(sermon.id, () => []);
            episodeFixes[sermon.id]!.add({
              'id': episode.id,
              'audioUrl': episode.audioUrl,
            });
          }
        }
      }
    }

    int total = sermonsToFix.length + episodeFixes.length;
    int completed = 0;

    for (final entry in sermonsToFix.entries) {
      try {
        final dur = await extractDurationFromUrl(entry.value);
        if (dur != null && dur.inMilliseconds > 0) {
          final durStr = formatDuration(dur);
          _durationCache[entry.key] = durStr;
          await FirebaseFirestore.instance
              .collection('sermons')
              .doc(entry.key)
              .update({'duration': durStr});
          notifyListeners();
        }
      } catch (_) {
        AppLogger.debug("Backfill failed for ${entry.key}", _);
      }
      completed++;
      onProgress?.call(completed, total);
    }

    for (final entry in episodeFixes.entries) {
      final docRef =
          FirebaseFirestore.instance.collection('sermons').doc(entry.key);
      final doc = await docRef.get();
      if (!doc.exists) continue;

      final data = doc.data()!;
      final episodes = List<Map<String, dynamic>>.from(
        (data['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
      bool changed = false;

      for (final fix in entry.value) {
        final epId = fix['id'] as String;
        final audioUrl = fix['audioUrl'] as String;
        final index = episodes.indexWhere((e) => e['id'] == epId);
        if (index == -1) continue;

        try {
          final dur = await extractDurationFromUrl(audioUrl);
          if (dur != null && dur.inMilliseconds > 0) {
            final durStr = formatDuration(dur);
            episodes[index]['duration'] = durStr;
            _durationCache[epId] = durStr;
            changed = true;
          }
        } catch (_) {
          AppLogger.debug("Backfill failed for episode $epId", _);
        }
        completed++;
        onProgress?.call(completed, total);
      }

      if (changed) {
        await docRef.update({'episodes': episodes});
        notifyListeners();
      }
    }

    return {'fixed': completed, 'failed': total - completed};
  }

  Future<String> _uploadFile({
    File? file,
    Uint8List? bytes,
    required String path,
    Function(double)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: 'audio/mpeg');

    UploadTask uploadTask;
    if (kIsWeb && bytes != null) {
      uploadTask = ref.putData(bytes, metadata);
    } else if (file != null) {
      uploadTask = ref.putFile(file, metadata);
    } else {
      throw Exception("No file or bytes provided for upload");
    }

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) onProgress(progress);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

// ================= ADMIN ACTIONS =================

  Future<Sermon> uploadSermon({
    required String title,
    required String speaker,
    required String description,
    required SermonCategory category,
    required MessageType type,
    File? audioFile,
    Uint8List? webAudioBytes,
    String? imageUrl,
    Function(double)? onProgress,
  }) async {
    try {
      String audioUrl = "";

      if (type == MessageType.single &&
          (audioFile != null || webAudioBytes != null)) {
        audioUrl = await _uploadFile(
          file: audioFile,
          bytes: webAudioBytes,
          path: 'audio/${DateTime.now().millisecondsSinceEpoch}.mp3',
          onProgress: onProgress,
        );
      }

      // Extract real duration from the uploaded audio
      String durationStr = '0:00';
      if (audioUrl.isNotEmpty) {
        try {
          final dur = await extractDurationFromUrl(audioUrl);
          if (dur != null && dur.inMilliseconds > 0) {
            durationStr = formatDuration(dur);
          }
        } catch (_) {
          // Fall back to '0:00'
        }
      }

      final Map<String, dynamic> newSermonData = {
        'title': title,
        'speaker': speaker,
        'description': description,
        'category': category.name,
        'messageType': type.name,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl ?? "",
        'date': Timestamp.now(),
        'episodes': [], // Ensure this is initialized to avoid null-errors in UI
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'duration': durationStr,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('sermons')
          .add(newSermonData);

      return Sermon.fromFirestore(newSermonData, docRef.id);
    } catch (e) {
      AppLogger.debug("Upload Sermon Error", e);
      rethrow;
    }
  }

  Future<void> updateSermon({
    required String id,
    required String title,
    required String speaker,
    required String description,
    required SermonCategory category,
    String? imageUrl,
    File? newAudioFile,
    Uint8List? newWebAudioBytes,
    Function(double)? onProgress,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'title': title,
        'speaker': speaker,
        'description': description,
        'category': category.name,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        updates['imageUrl'] = imageUrl;
      }

      if (newAudioFile != null || newWebAudioBytes != null) {
        String audioUrl = await _uploadFile(
          file: newAudioFile,
          bytes: newWebAudioBytes,
          path: 'audio/${DateTime.now().millisecondsSinceEpoch}.mp3',
          onProgress: onProgress,
        );
        updates['audioUrl'] = audioUrl;

        // Recalculate duration for the new audio file
        try {
          final dur = await extractDurationFromUrl(audioUrl);
          if (dur != null && dur.inMilliseconds > 0) {
            updates['duration'] = formatDuration(dur);
          }
        } catch (_) {}
      }

      await FirebaseFirestore.instance
          .collection('sermons')
          .doc(id)
          .update(updates);
    } catch (e) {
      AppLogger.debug("Update Error", e);
      rethrow;
    }
  }

  Future<void> updateEpisode({
    required String seriesId,
    required String episodeId,
    required String title,
    required String speaker,
    required String description,
    File? newAudioFile,
    Uint8List? newWebAudioBytes,
    Function(double)? onProgress,
  }) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('sermons').doc(seriesId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      List<dynamic> episodes = List.from(doc.data()?['episodes'] ?? []);
      int index = episodes.indexWhere((e) => e['id'].toString() == episodeId);

      if (index != -1) {
        Map<String, dynamic> episodeData =
            Map<String, dynamic>.from(episodes[index]);
        episodeData['title'] = title;
        episodeData['speaker'] = speaker;
        episodeData['description'] = description;

        if (newAudioFile != null || newWebAudioBytes != null) {
          String url = await _uploadFile(
            file: newAudioFile,
            bytes: newWebAudioBytes,
            path: 'audio/episodes/${DateTime.now().millisecondsSinceEpoch}.mp3',
            onProgress: onProgress,
          );
          episodeData['audioUrl'] = url;

          // Recalculate duration for the new audio file
          try {
            final dur = await extractDurationFromUrl(url);
            if (dur != null && dur.inMilliseconds > 0) {
              episodeData['duration'] = formatDuration(dur);
            }
          } catch (_) {}
        }

        episodes[index] = episodeData;
        await docRef.update({'episodes': episodes});
      }
    } catch (e) {
      AppLogger.debug("Update Episode Error", e);
      rethrow;
    }
  }

  Future<void> deleteEpisode(String seriesId, String episodeId) async {
    try {
      // 1. Optimistic Update
      int seriesIndex = _sermons.indexWhere((s) => s.id == seriesId);
      String? audioToCleanup;

      if (seriesIndex != -1) {
        final List<Episode> currentEpisodes =
            List.from(_sermons[seriesIndex].episodes);
        final episodeIndex =
            currentEpisodes.indexWhere((e) => e.id == episodeId);

        if (episodeIndex != -1) {
          audioToCleanup = currentEpisodes[episodeIndex].audioUrl;
          currentEpisodes.removeAt(episodeIndex);

          // Use copyWith to update local state safely
          _sermons[seriesIndex] =
              _sermons[seriesIndex].copyWith(episodes: currentEpisodes);
          notifyListeners();
        }
      }

      // 2. Database Update
      final docRef =
          FirebaseFirestore.instance.collection('sermons').doc(seriesId);
      final doc = await docRef.get();

      if (doc.exists) {
        List episodes = List.from(doc.data()?['episodes'] ?? []);
        episodes.removeWhere((e) => e['id'].toString() == episodeId);
        await docRef.update({'episodes': episodes});

        // 3. Storage Cleanup
        if (audioToCleanup != null && audioToCleanup.isNotEmpty) {
          _deleteFileFromStorage(audioToCleanup);
        }
      }
    } catch (e) {
      AppLogger.debug("Delete Episode Error", e);
      _listenToSermons(); // Restore state on failure
      rethrow;
    }
  }

  Future<void> addEpisodeToSeries({
    required String seriesId,
    required String title,
    required String speaker,
    required String description,
    File? audioFile,
    Uint8List? webAudioBytes,
    required int episodeNumber,
    Function(double)? onProgress,
  }) async {
    try {
      String audioUrl = await _uploadFile(
        file: audioFile,
        bytes: webAudioBytes,
        path: 'audio/episodes/${DateTime.now().millisecondsSinceEpoch}.mp3',
        onProgress: onProgress,
      );

      final docRef =
          FirebaseFirestore.instance.collection('sermons').doc(seriesId);

      // Extract real duration from the uploaded episode audio
      String episodeDuration = '0:00';
      try {
        final dur = await extractDurationFromUrl(audioUrl);
        if (dur != null && dur.inMilliseconds > 0) {
          episodeDuration = formatDuration(dur);
        }
      } catch (_) {
        // Fall back to '0:00'
      }

      final newEpisode = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'speaker': speaker,
        'description': description,
        'audioUrl': audioUrl,
        'episodeNumber': episodeNumber,
        'duration': episodeDuration,
        'date': Timestamp.now(),
        'playCount': 0,
      };

      await docRef.update({
        'episodes': FieldValue.arrayUnion([newEpisode])
      });
    } catch (e) {
      AppLogger.debug("Add Episode Error", e);
      rethrow;
    }
  }

  Future<void> deleteSermon(String id) async {
    try {
      _sermons.removeWhere((s) => s.id == id);
      notifyListeners();

      final docRef = FirebaseFirestore.instance.collection('sermons').doc(id);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data['audioUrl'] != null &&
            data['audioUrl'].toString().isNotEmpty) {
          _deleteFileFromStorage(data['audioUrl']);
        }

        // Also cleanup storage for all episodes if it's a series
        if (data['episodes'] != null) {
          for (var episode in (data['episodes'] as List)) {
            if (episode['audioUrl'] != null) {
              _deleteFileFromStorage(episode['audioUrl']);
            }
          }
        }

        await docRef.delete();
      }
    } catch (e) {
      AppLogger.debug("Delete Sermon Error", e);
      _listenToSermons();
      rethrow;
    }
  }

  Future<void> _deleteFileFromStorage(String url) async {
    try {
      if (url.contains('firebasestorage')) {
        await FirebaseStorage.instance.refFromURL(url).delete();
      }
    } catch (e) {
      AppLogger.debug("Storage Cleanup Error", e);
    }
  }

  @override
  Sermon? getNextContextItem(String currentId, PlaybackContext context,
      ContentType type, List<Sermon> currentFilter) {
    int index = currentFilter.indexWhere((s) => s.id == currentId);
    if (index != -1 && index < currentFilter.length - 1) {
      return currentFilter[index + 1];
    }
    return null;
  }

  @override
  void dispose() {
    _sermonSubscription?.cancel();
    super.dispose();
  }
}
