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
        return Sermon.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      _isLoading = false;

      // Update local cache
      StorageService().saveSermons(_sermons);
      notifyListeners();
    }, onError: (error) {
      debugPrint("Firestore Listener Error: $error");
      _isLoading = false;
      notifyListeners();
    });
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
      };

      final docRef = await FirebaseFirestore.instance
          .collection('sermons')
          .add(newSermonData);

      return Sermon.fromFirestore(newSermonData, docRef.id);
    } catch (e) {
      debugPrint("Upload Sermon Error: $e");
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
      }

      await FirebaseFirestore.instance
          .collection('sermons')
          .doc(id)
          .update(updates);
    } catch (e) {
      debugPrint("Update Error: $e");
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
        }

        episodes[index] = episodeData;
        await docRef.update({'episodes': episodes});
      }
    } catch (e) {
      debugPrint("Update Episode Error: $e");
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
      debugPrint("Delete Episode Error: $e");
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

      final newEpisode = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'speaker': speaker,
        'description': description,
        'audioUrl': audioUrl,
        'episodeNumber': episodeNumber,
        'duration': "0:00",
        'date': Timestamp.now(),
        'playCount': 0,
      };

      await docRef.update({
        'episodes': FieldValue.arrayUnion([newEpisode])
      });
    } catch (e) {
      debugPrint("Add Episode Error: $e");
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
      debugPrint("Delete Sermon Error: $e");
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
      debugPrint("Storage Cleanup Error: $e");
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
