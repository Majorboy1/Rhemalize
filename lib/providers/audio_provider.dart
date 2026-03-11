import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_session/audio_session.dart'; // Added for professional session handling
import '../models/sermon.dart';
import '../services/audio_service.dart';

enum PlaybackContext { home, library }

enum ContentType { series, single }

abstract class PlaybackDataDelegate {
  Sermon? getNextContextItem(String currentId, PlaybackContext context,
      ContentType type, List<Sermon> currentFilter);
}

class PlaybackSession {
  final PlaybackContext context;
  final ContentType type;
  final List<Sermon> originalList;
  PlaybackSession(
      {required this.context, required this.type, required this.originalList});
}

class AudioProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _playedKey = 'played_sermon_ids';
  static const String _lastListenKey = 'last_listen_date';

  // Fallback image for notifications if sermon art is missing
  static const String _fallbackArt =
      "https://rhemalize-church-audio-app.web.app/assets/icon.png";

  PlaybackDataDelegate? dataDelegate;
  PlaybackSession? _session;

  Sermon? _currentSermon;
  Episode? _currentEpisode;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _showFullPlayer = false;
  bool _isShuffleOn = false;
  LoopMode _loopMode = LoopMode.off;
  double _speed = 1.0;

  final Set<String> _playedIds = {};
  DateTime _lastListenDate = DateTime.now();

  AudioProvider() {
    _configureAudioEngine();
    _listenToStates();
    _loadPlayedHistory();
  }

  Future<void> _configureAudioEngine() async {
    // --- SUGGESTION ADDED: Configure Audio Session for Background & WakeLock ---
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _audioService.player
        .setAudioSource(ConcatenatingAudioSource(children: []), preload: true);
  }

  // ================= GETTERS =================
  Sermon? get currentSermon => _currentSermon;
  Episode? get currentEpisode => _currentEpisode;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get showFullPlayer => _showFullPlayer;
  Set<String> get playedSermonIds => _playedIds;
  DateTime get lastListenDate => _lastListenDate;
  bool get isShuffleOn => _isShuffleOn;
  LoopMode get loopMode => _loopMode;
  double get speed => _speed;
  bool get hasNext => _audioService.player.hasNext;
  bool get hasPrevious => _audioService.player.hasPrevious;
  PlaybackSession? get playbackSession => _session;

  // ================= STATE LISTENERS =================

  void _listenToStates() {
    _audioService.player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioService.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _audioService.player.playerStateStream.listen((state) async {
      _isPlaying = state.playing;

      _isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        if (_loopMode == LoopMode.off && !hasNext) {
          await _handleTrackEnded();
        }
      }
      notifyListeners();
    });

    _audioService.player.currentIndexStream.listen((index) {
      _syncMetadata();
    });

    _audioService.player.speedStream.listen((s) {
      _speed = s;
      notifyListeners();
    });
  }

  void _syncMetadata() {
    final index = _audioService.player.currentIndex;
    if (index != null && _session != null) {
      if (_session!.type == ContentType.series && _currentSermon != null) {
        if (index < _currentSermon!.episodes.length) {
          _currentEpisode = _currentSermon!.episodes[index];
          _handleNewPlay(_currentEpisode!.id,
              isEpisode: true, parentSermonId: _currentSermon!.id);
        }
      } else {
        if (index < _session!.originalList.length) {
          _currentSermon = _session!.originalList[index];
          _currentEpisode = null;
          _handleNewPlay(_currentSermon!.id, isEpisode: false);
        }
      }
      notifyListeners();
    }
  }

  // ================= STREAK & FIRESTORE LOGIC =================

  Future<void> _updateStreakInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      final doc = await userRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final DateTime now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime lastDate = today;
      if (data['lastListenDate'] != null) {
        lastDate = (data['lastListenDate'] as Timestamp).toDate();
      }
      final lastListen = DateTime(lastDate.year, lastDate.month, lastDate.day);

      final int currentStreak = data['streak'] ?? 0;
      final difference = today.difference(lastListen).inDays;

      if (difference == 1) {
        await userRef.update({
          'streak': FieldValue.increment(1),
          'lastListenDate': Timestamp.fromDate(today),
        });
      } else if (difference > 1 || currentStreak == 0) {
        await userRef.update({
          'streak': 1,
          'lastListenDate': Timestamp.fromDate(today),
        });
      }
    } catch (e) {
      debugPrint("Streak Update Error: $e");
    }
  }

  Future<void> _recordListenToFirestore(String id, bool isEpisode,
      {String? parentSermonId}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await _firestore.collection('listens').add({
        'contentId': id,
        'parentSermonId': parentSermonId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isEpisode': isEpisode,
      });

      final sermonId = isEpisode ? parentSermonId : id;
      if (sermonId != null) {
        DocumentReference sermonRef =
            _firestore.collection('sermons').doc(sermonId);

        if (!isEpisode) {
          await sermonRef.update({'playCount': FieldValue.increment(1)});
        } else {
          final doc = await sermonRef.get();
          if (doc.exists) {
            List<dynamic> episodes = doc.get('episodes') ?? [];
            for (var e in episodes) {
              if (e['id'] == id) {
                e['playCount'] = (e['playCount'] ?? 0) + 1;
                break;
              }
            }
            await sermonRef.update({
              'playCount': FieldValue.increment(1),
              'episodes': episodes,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error recording listen: $e");
    }
  }

  // ================= CONTROLS =================

  void seek(Duration pos) => _audioService.player.seek(pos);

  void setSpeed(double speed) {
    _speed = speed;
    _audioService.player.setSpeed(speed);
    notifyListeners();
  }

  void cycleSpeed() {
    if (_speed == 1.0) {
      _speed = 1.5;
    } else if (_speed == 1.5) {
      _speed = 2.0;
    } else {
      _speed = 1.0;
    }
    _audioService.player.setSpeed(_speed);
    notifyListeners();
  }

  void playSermon(
      Sermon sermon, List<Sermon> currentList, PlaybackContext context) {
    if (sermon.audioUrl.isEmpty && sermon.messageType == MessageType.single)
      return;

    if (sermon.messageType == MessageType.series &&
        sermon.episodes.isNotEmpty) {
      playEpisode(sermon, sermon.episodes.first, currentList, context);
      return;
    }

    _session = PlaybackSession(
        context: context,
        type: ContentType.single,
        originalList: List.from(currentList));
    _currentSermon = sermon;
    _currentEpisode = null;

    final playlist = ConcatenatingAudioSource(
      children: _session!.originalList
          .where((s) => s.audioUrl.isNotEmpty)
          .map((s) => AudioSource.uri(
                Uri.parse(_convertToDirectLink(s.audioUrl)),
                tag: MediaItem(
                    id: s.id,
                    album: s.seriesTitle ?? "Single",
                    title: s.title,
                    artist: s.speaker,
                    // --- SUGGESTION ADDED: ArtUri safety fallback ---
                    artUri: Uri.parse(
                        (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                            ? s.imageUrl!
                            : _fallbackArt)),
              ))
          .toList(),
    );

    int index = _session!.originalList.indexWhere((s) => s.id == sermon.id);
    _executePlay(
        id: sermon.id,
        playlist: playlist,
        initialIndex: index >= 0 ? index : 0,
        isEpisode: false);
  }

  void playEpisode(Sermon series, Episode episode, List<Sermon> currentList,
      PlaybackContext context) {
    if (episode.audioUrl.isEmpty) return;

    _session = PlaybackSession(
        context: context,
        type: ContentType.series,
        originalList: List.from(currentList));
    _currentSermon = series;
    _currentEpisode = episode;

    final playlist = ConcatenatingAudioSource(
      children: series.episodes
          .where((e) => e.audioUrl.isNotEmpty)
          .map((e) => AudioSource.uri(
                Uri.parse(_convertToDirectLink(e.audioUrl)),
                tag: MediaItem(
                    id: e.id,
                    album: series.title,
                    title: e.title,
                    artist: e.speaker,
                    // --- SUGGESTION ADDED: ArtUri safety fallback ---
                    artUri: Uri.parse(
                        (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                            ? e.imageUrl!
                            : (series.imageUrl ?? _fallbackArt))),
              ))
          .toList(),
    );

    int index = series.episodes.indexWhere((e) => e.id == episode.id);
    _executePlay(
        id: episode.id,
        playlist: playlist,
        initialIndex: index >= 0 ? index : 0,
        isEpisode: true,
        parentSermonId: series.id);
  }

  Future<void> _executePlay(
      {required String id,
      required ConcatenatingAudioSource playlist,
      required int initialIndex,
      required bool isEpisode,
      String? parentSermonId}) async {
    _handleNewPlay(id, isEpisode: isEpisode, parentSermonId: parentSermonId);
    _showFullPlayer = true;
    _isBuffering = true;
    notifyListeners();

    try {
      await _audioService.player
          .setAudioSource(playlist, initialIndex: initialIndex);
      await _audioService.player.setSpeed(_speed);
      await _audioService.play();
    } catch (e) {
      debugPrint("Audio Play Error: $e");
      _isBuffering = false;
      notifyListeners();
    } finally {
      _isBuffering = false;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    if (_currentSermon == null && _currentEpisode == null) return;
    _isPlaying ? _audioService.pause() : _audioService.play();
  }

  void playNext() => _audioService.player.seekToNext();
  void playPrevious() => _audioService.player.seekToPrevious();

  void stop() {
    _audioService.stop();
    _currentSermon = null;
    _currentEpisode = null;
    _session = null;
    _isBuffering = false;
    _isPlaying = false;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    _audioService.player.setShuffleModeEnabled(_isShuffleOn);
    notifyListeners();
  }

  void toggleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    _audioService.player.setLoopMode(_loopMode);
    notifyListeners();
  }

  String _convertToDirectLink(String? url) {
    if (url == null || !url.contains('drive.google.com')) return url ?? "";
    final regExp = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match != null
        ? 'https://drive.google.com/uc?export=download&id=${match.group(1)}'
        : url;
  }

  void _handleNewPlay(String id,
      {bool isEpisode = false, String? parentSermonId}) {
    if (!_playedIds.contains(id)) {
      _playedIds.add(id);
      _savePlayedHistory();
      _updateLastListenDate();
      _updateStreakInFirestore();
    }
    _recordListenToFirestore(id, isEpisode, parentSermonId: parentSermonId);
  }

  Future<void> _updateLastListenDate() async {
    final prefs = await SharedPreferences.getInstance();
    _lastListenDate = DateTime.now();
    await prefs.setString(_lastListenKey, _lastListenDate.toIso8601String());
    notifyListeners();
  }

  Future<void> _loadPlayedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedIds = prefs.getStringList(_playedKey);
    if (savedIds != null) _playedIds.addAll(savedIds);
    final String? dateStr = prefs.getString(_lastListenKey);
    if (dateStr != null) _lastListenDate = DateTime.parse(dateStr);
    notifyListeners();
  }

  Future<void> _savePlayedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playedKey, _playedIds.toList());
  }

  Future<void> clearPlayedHistory() async {
    _playedIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playedKey);
    notifyListeners();
  }

  void openFullPlayer() {
    _showFullPlayer = true;
    notifyListeners();
  }

  void closeFullPlayer() {
    _showFullPlayer = false;
    notifyListeners();
  }

  Future<void> _handleTrackEnded() async {
    if (_session != null && dataDelegate != null && _currentSermon != null) {
      final next = dataDelegate!.getNextContextItem(_currentSermon!.id,
          _session!.context, _session!.type, _session!.originalList);
      if (next != null)
        playSermon(next, _session!.originalList, _session!.context);
      else
        stop();
    }
  }
}
