import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import '../providers/audio_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '653124289726-mma5hdf4i1ml661d7449be13p8endvh2.apps.googleusercontent.com'
        : null,
    scopes: <String>['email'],
  );

  User? _user;
  String? _userRole;
  bool _isLoading = false;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _updateUserStats(user);
        if (!kIsWeb) {
          try {
            await FirebaseMessaging.instance.subscribeToTopic('new_sermons');
          } catch (e) {
            debugPrint("FCM not supported on this platform: $e");
          }
        }
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _updateUserStats(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      final photoUrl = user.photoURL;
      final email = user.email?.trim().toLowerCase();
      var resolvedRole = 'user';

      if (email != null && email.isNotEmpty) {
        final adminDoc = await _firestore.collection('admins').doc(email).get();
        if (adminDoc.exists) {
          resolvedRole = 'admin';
        }
      }

      if (!docSnapshot.exists) {
        _userRole = resolvedRole;
        await userDoc.set({
          'email': user.email,
          'name': user.displayName,
          'photoUrl': photoUrl,
          'role': resolvedRole,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = docSnapshot.data();
        final storedRole = (data?['role'] ?? '').toString().toLowerCase();
        _userRole = resolvedRole == 'admin'
            ? 'admin'
            : (storedRole.isEmpty ? 'user' : storedRole);
        await userDoc.update({
          'email': user.email,
          'name': user.displayName,
          'photoUrl': photoUrl,
          'role': _userRole,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating user stats: $e");
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final signedInUser = userCredential.user;

      if (signedInUser != null) {
        final googlePhotoUrl = googleUser.photoUrl;
        final googleDisplayName = googleUser.displayName;

        if (googleDisplayName != null &&
            googleDisplayName.isNotEmpty &&
            signedInUser.displayName != googleDisplayName) {
          await signedInUser.updateDisplayName(googleDisplayName);
        }

        if (googlePhotoUrl != null &&
            googlePhotoUrl.isNotEmpty &&
            signedInUser.photoURL != googlePhotoUrl) {
          await signedInUser.updatePhotoURL(googlePhotoUrl);
        }

        await signedInUser.reload();
        _user = _auth.currentUser;
        if (_user != null) {
          await _updateUserStats(_user!);
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      _setLoading(true);
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Authentication failed";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut({AudioProvider? audioProvider}) async {
    try {
      if (audioProvider != null) audioProvider.stop();
      if (!kIsWeb) {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('new_sermons')
            .catchError((_) {});
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _userRole = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Sign-Out Error: $e");
    }
  }

  // --- INTERNAL HELPER ---
  Future<String> _uploadFile(
    String path, {
    File? file,
    Uint8List? bytes,
    Function(double)? onProgress,
  }) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask;

    final metadata = SettableMetadata(contentType: 'audio/mpeg');

    // FIX: Optimized logic for Web vs Mobile
    if (kIsWeb) {
      if (bytes == null) throw Exception("Web upload requires audio bytes.");
      uploadTask = ref.putData(bytes, metadata);
    } else {
      if (file != null) {
        uploadTask = ref.putFile(file, metadata);
      } else if (bytes != null) {
        uploadTask = ref.putData(bytes, metadata);
      } else {
        throw Exception("No audio source provided for upload.");
      }
    }

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }
    });

    TaskSnapshot completedSnapshot = await uploadTask;
    return await completedSnapshot.ref.getDownloadURL();
  }

  // --- SINGLE UPLOAD ---
  Future<void> uploadOneTimeSermon({
    required String title,
    required String pastor,
    File? audioFile,
    Uint8List? audioBytes,
    required String imageUrl,
    required String description,
    required String category,
    required Function(double) onProgress,
  }) async {
    try {
      String fileName = 'sermons/${const Uuid().v4()}.mp3';
      String downloadUrl = await _uploadFile(
        fileName,
        file: audioFile,
        bytes: audioBytes,
        onProgress: onProgress,
      );

      await _firestore.collection('sermons').add({
        'title': title,
        'speaker': pastor,
        'audioUrl': downloadUrl,
        'imageUrl': imageUrl,
        'description': description,
        'category': category,
        'messageType': 'single',
        'date': FieldValue.serverTimestamp(),
        'playCount': 0,
        'uploaderId': _user?.uid,
      });
    } catch (e) {
      debugPrint("Upload Error: $e");
      rethrow;
    }
  }

  // --- SERIES UPLOAD ---
  Future<void> uploadSeriesSermon({
    required String title,
    required String pastor,
    required String imageUrl,
    required String description,
    required List<Map<String, dynamic>> episodes,
    required String category,
    required Function(double) onProgress,
  }) async {
    try {
      List<Map<String, dynamic>> uploadedEpisodes = [];

      for (int i = 0; i < episodes.length; i++) {
        var ep = episodes[i];
        String fileName = 'series/${const Uuid().v4()}.mp3';

        // FIX: Using 'audioFile' and 'audioBytes' keys to match UI Screen
        String url = await _uploadFile(
          fileName,
          file: ep['audioFile'] as File?,
          bytes: ep['audioBytes'] as Uint8List?,
          onProgress: (fileProgress) {
            double totalProgress = (i + fileProgress) / episodes.length;
            onProgress(totalProgress);
          },
        );

        uploadedEpisodes.add({
          'id': const Uuid().v4(),
          'title': ep['title'],
          'audioUrl': url,
          'speaker': pastor,
          'date': DateTime.now().toIso8601String(),
          'episodeNumber': i + 1,
          'duration': '0:00',
          'description': description,
          'playCount': 0,
        });
      }

      await _firestore.collection('sermons').add({
        'title': title,
        'speaker': pastor,
        'imageUrl': imageUrl,
        'description': description,
        'category': category,
        'messageType': 'series',
        'episodes': uploadedEpisodes,
        'date': FieldValue.serverTimestamp(),
        'playCount': 0,
        'uploaderId': _user?.uid,
      });
    } catch (e) {
      debugPrint("Series Upload Error: $e");
      rethrow;
    }
  }

  // --- PASTOR MANAGEMENT ---
  Future<void> createNewPastor(
      {required String name, required String role}) async {
    await _firestore.collection('pastors').add({
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> updatePastor(
      {required String docId,
      required String name,
      required String role}) async {
    await _firestore.collection('pastors').doc(docId).update({
      'name': name,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> deletePastor(String docId) async {
    await _firestore.collection('pastors').doc(docId).delete();
    notifyListeners();
  }
}



