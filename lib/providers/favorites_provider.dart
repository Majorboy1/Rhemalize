import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sermon.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favoriteIds = {};
  List<Sermon> _allSermons = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Set<String> get favoriteSermonIds => _favoriteIds;

  FavoritesProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadFavoritesFromFirestore();
      } else {
        _favoriteIds.clear();
        notifyListeners();
      }
    });
  }

  void setSermons(List<Sermon> sermons) {
    _allSermons = sermons;
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  Future<bool> toggleFavorite(String id) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = _firestore.collection('users').doc(user.uid);
    bool added;

    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      added = false;
      notifyListeners();
      await userDoc.update({
        'favorites': FieldValue.arrayRemove([id])
      });
    } else {
      _favoriteIds.add(id);
      added = true;
      notifyListeners();
      await userDoc.set({
        'favorites': FieldValue.arrayUnion([id])
      }, SetOptions(merge: true));
    }
    return added;
  }

  Future<void> loadFavoritesFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic> remoteFavorites = doc.data()!['favorites'] ?? [];
        _favoriteIds.clear();
        _favoriteIds.addAll(remoteFavorites.map((e) => e.toString()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  List<Sermon> get favoriteSermons {
    List<Sermon> favorites = [];
    for (var sermon in _allSermons) {
      // Add standard sermons
      if (_favoriteIds.contains(sermon.id)) {
        favorites.add(sermon);
      }
      // Add episodes from series
      for (var episode in sermon.episodes) {
        if (_favoriteIds.contains(episode.id)) {
          favorites.add(Sermon(
            id: episode.id,
            title: episode.title,
            speaker: episode.speaker,
            imageUrl: episode.imageUrl ?? sermon.imageUrl,
            audioUrl: episode.audioUrl,
            category: sermon.category,
            description: episode.description,
            date: episode.date,
            duration: episode.duration,
            messageType: MessageType.single,
            episodes: [],
            seriesTitle: sermon.title, // Critical for UI display
          ));
        }
      }
    }
    return favorites;
  }
}
