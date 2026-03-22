import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sermon.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favoriteIds = {};
  List<Sermon> _allSermons = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _favoritesSubscription;

  Set<String> get favoriteSermonIds => _favoriteIds;

  FavoritesProvider() {
    _auth.authStateChanges().listen((user) {
      _favoritesSubscription?.cancel();
      if (user != null) {
        _listenToFavorites(user.uid);
      } else {
        _favoriteIds.clear();
        notifyListeners();
      }
    });
  }

  void _listenToFavorites(String userId) {
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final List<dynamic> remoteFavorites = data?['favorites'] ?? [];
      _favoriteIds
        ..clear()
        ..addAll(remoteFavorites.map((e) => e.toString()));
      notifyListeners();
    }, onError: (e) {
      debugPrint('Favorite Sync Error: $e');
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
    final wasFavorite = _favoriteIds.contains(id);

    if (wasFavorite) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await userDoc.set({
          'favorites': FieldValue.arrayRemove([id])
        }, SetOptions(merge: true));
      } else {
        await userDoc.set({
          'favorites': FieldValue.arrayUnion([id])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (wasFavorite) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
      debugPrint('Favorite Sync Error: $e');
    }

    return !wasFavorite;
  }

  List<Sermon> get favoriteSermons {
    final List<Sermon> favorites = [];
    for (final sermon in _allSermons) {
      if (_favoriteIds.contains(sermon.id)) {
        favorites.add(sermon);
      }
      for (final episode in sermon.episodes) {
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
            episodes: const [],
            seriesTitle: sermon.title,
          ));
        }
      }
    }
    return favorites;
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
