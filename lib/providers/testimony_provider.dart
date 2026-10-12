import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/testimony.dart';

class TestimonyProvider with ChangeNotifier {
  List<Testimony> _testimonies = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Testimony> get testimonies => _testimonies;
  bool get isLoading => _isLoading;

  TestimonyProvider() {
    _listenToTestimonies();
  }

  void _listenToTestimonies() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('testimonies')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _testimonies = snapshot.docs
          .map((doc) => Testimony.fromFirestore(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String> uploadTestimony({
    required String title,
    required String speaker,
    required String description,
    required Uint8List audioBytes,
    required String fileName,
    DateTime? date,
    String? imageUrl,
    Function(double)? onProgress,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('testimonies').doc();
    final storagePath = 'testimonies/${docRef.id}/$fileName';
    final uploadRef = FirebaseStorage.instance.ref().child(storagePath);

    final uploadTask = uploadRef.putData(
      audioBytes,
      SettableMetadata(contentType: 'audio/mpeg'),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress.clamp(0.0, 1.0));
      }
    });

    final completedSnapshot = await uploadTask;
    final audioUrl = await completedSnapshot.ref.getDownloadURL();

    final testimony = Testimony(
      id: docRef.id,
      title: title.trim(),
      speaker: speaker.trim(),
      date: date ?? DateTime.now(),
      duration: '',
      audioUrl: audioUrl,
      description: description.trim(),
      imageUrl: imageUrl,
      playCount: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(testimony.toFirestore());
    return docRef.id;
  }

  Future<void> deleteTestimony(String id) async {
    final ref = FirebaseFirestore.instance.collection('testimonies').doc(id);
    await ref.delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
