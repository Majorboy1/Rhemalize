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

  // UPDATED: Optimistic UI for instant feedback
  Future<bool> toggleFavorite(String id) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = _firestore.collection('users').doc(user.uid);
    bool added;

    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id); // Remove locally first
      added = false;
    } else {
      _favoriteIds.add(id); // Add locally first
      added = true;
    }

    // Notify UI immediately before the network call
    notifyListeners();

    try {
      if (added) {
        await userDoc.set({
          'favorites': FieldValue.arrayUnion([id])
        }, SetOptions(merge: true));
      } else {
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([id])
        });
      }
    } catch (e) {
      // Rollback on error if network fails
      if (added)
        _favoriteIds.remove(id);
      else
        _favoriteIds.add(id);
      notifyListeners();
      debugPrint("Favorite Sync Error: $e");
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
      if (_favoriteIds.contains(sermon.id)) {
        favorites.add(sermon);
      }
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
            seriesTitle: sermon.title,
          ));
        }
      }
    }
    return favorites;
  }
}
