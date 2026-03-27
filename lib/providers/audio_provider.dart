import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_session/audio_session.dart';
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
  static const String _playedOrderKey = 'played_sermon_order';
  static const String _lastListenKey = 'last_listen_date';
  static const String _positionPrefix = 'resume_pos_';
  static const String _lastResumeKey = 'last_resume_id';
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
  String? _lastError;

  final Set<String> _playedIds = {};
  final List<String> _playedOrder = [];
  final Map<String, int> _resumePositions = {};
  DateTime _lastListenDate = DateTime.now();
  String? _lastResumableId;
  String? _lastTrackId;
  Timer? _positionSaveTimer; // Timer for background position saving
  String? _pendingHistoryTrackId;
  String? _pendingHistorySermonId;
  bool _pendingHistoryIsEpisode = false;
  bool _pendingHistoryCommitted = false;

  AudioProvider() {
    _initAudio();
    _listenToStates();
    _loadPlayedHistory();
  }

  Future<void> _initAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
  List<String> get recentPlayedIds => List.unmodifiable(_playedOrder);
  DateTime get lastListenDate => _lastListenDate;
  String? get lastResumableId => _lastResumableId;
  bool get isShuffleOn => _isShuffleOn;
  LoopMode get loopMode => _loopMode;
  double get speed => _speed;
  String? get lastError => _lastError;
  Duration getSavedPosition(String id) =>
      Duration(milliseconds: _resumePositions[id] ?? 0);
  bool get hasNext => _audioService.player.hasNext;
  bool get hasPrevious => _audioService.player.hasPrevious;
  PlaybackSession? get playbackSession => _session;

  // ================= STATE LISTENERS =================

  void _listenToStates() {
    _audioService.player.positionStream.listen((pos) {
      _position = pos;
      _commitPendingHistoryIfNeeded();
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

      if (state.playing) {
        _startPositionTracking();
      } else {
        _stopPositionTracking();
      }

      if (state.processingState == ProcessingState.completed) {
        // Clear saved position when finished
        final id = _currentEpisode?.id ?? _currentSermon?.id;
        if (id != null) _clearSavedPosition(id);

        if (_loopMode == LoopMode.off && !hasNext) {
          await _handleTrackEnded();
        }
      }
      notifyListeners();
    });

    _audioService.player.currentIndexStream.listen((index) {
      _syncMetadata(index);
    });

    _audioService.player.speedStream.listen((s) {
      _speed = s;
      notifyListeners();
    });
  }

  void _syncMetadata(int? index) {
    if (index == null || _session == null) return;

    final sequence = _audioService.player.sequence;
    if (index < 0 || index >= sequence.length) return;

    final tag = sequence[index].tag;
    if (tag is! MediaItem) return;

    if (_session!.type == ContentType.series && _currentSermon != null) {
      Episode? matchedEpisode;
      for (final episode in _currentSermon!.episodes) {
        if (episode.audioUrl.isNotEmpty && episode.id == tag.id) {
          matchedEpisode = episode;
          break;
        }
      }
      if (matchedEpisode == null) return;

      _currentEpisode = matchedEpisode;
      _handleNewPlay(
        matchedEpisode.id,
        isEpisode: true,
        parentSermonId: _currentSermon!.id,
      );
    } else {
      Sermon? matchedSermon;
      for (final sermon in _session!.originalList) {
        if (sermon.audioUrl.isNotEmpty && sermon.id == tag.id) {
          matchedSermon = sermon;
          break;
        }
      }
      if (matchedSermon == null) return;

      _currentSermon = matchedSermon;
      _currentEpisode = null;
      _handleNewPlay(matchedSermon.id, isEpisode: false);
    }

    notifyListeners();
  }

  // ================= PERSISTENCE LOGIC =================

  void _startPositionTracking() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final id = _currentEpisode?.id ?? _currentSermon?.id;
      if (id != null && _isPlaying && _position.inSeconds > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('$_positionPrefix$id', _position.inMilliseconds);
      }
    });
  }

  void _stopPositionTracking() {
    _positionSaveTimer?.cancel();
  }

  Future<void> _clearSavedPosition(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_positionPrefix$id');
  }
// ================= STREAK & FIRESTORE LOGIC =================

  void _handleNewPlay(String id,
      {bool isEpisode = false, String? parentSermonId}) {
    if (_lastTrackId == id) return;

    final sermonId = isEpisode ? parentSermonId : id;
    if (sermonId != null) {
      _rememberPlaybackLocally(trackId: id, sermonId: sermonId);
    }

    _lastTrackId = id;
    _pendingHistoryTrackId = id;
    _pendingHistorySermonId = sermonId;
    _pendingHistoryIsEpisode = isEpisode;
    _pendingHistoryCommitted = false;
  }

  void _rememberPlaybackLocally({
    required String trackId,
    required String sermonId,
  }) {
    _playedIds.add(sermonId);
    _playedOrder.remove(trackId);
    _playedOrder.insert(0, trackId);
    unawaited(_savePlayedHistory());
    notifyListeners();
  }

  void _commitPendingHistoryIfNeeded() {
    // This is called by the positionStream listener in _listenToStates
    if (_pendingHistoryCommitted || _position.inSeconds < 30) return;

    final trackId = _pendingHistoryTrackId;
    final sermonId = _pendingHistorySermonId;
    if (trackId == null || sermonId == null) return;

    _pendingHistoryCommitted = true;

    // Update local state
    _playedIds.add(sermonId);
    _playedOrder.remove(trackId);
    _playedOrder.insert(0, trackId);
    _resumePositions[trackId] = _position.inMilliseconds;
    _lastResumableId = trackId;

    // Trigger persistent save immediately
    unawaited(_persistCommittedHistory(trackId, sermonId));
  }

  // Saves the specific ID of the track that was just played
  // so the "Continue Listening" card can find it later.
  Future<void> _saveLastResumableId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _lastResumableId = id; // Update local variable
    await prefs.setString(_lastResumeKey, id);
    notifyListeners();
  }

  Future<void> _persistCommittedHistory(String trackId, String sermonId) async {
    // 1. Save the list of IDs and the order to SharedPreferences
    await _savePlayedHistory();

    // 2. Save the specific track ID so it shows in the "Resume" card
    await _saveLastResumableId(trackId);

    // 3. Update the date and Firestore stats
    await _updateLastListenDate();
    await _updateStreakInFirestore();

    _recordListenToFirestore(
      trackId,
      _pendingHistoryIsEpisode,
      parentSermonId: _pendingHistoryIsEpisode ? sermonId : null,
    );

    notifyListeners();
  }

  Future<void> _updateStreakInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final DateTime now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        DateTime lastDate = today;
        if (data['lastListenDate'] != null) {
          lastDate = (data['lastListenDate'] as Timestamp).toDate();
        }
        final lastListen =
            DateTime(lastDate.year, lastDate.month, lastDate.day);

        final int currentStreak = data['streak'] ?? 0;
        final difference = today.difference(lastListen).inDays;

        if (difference == 1) {
          transaction.update(userRef, {
            'streak': FieldValue.increment(1),
            'lastListenDate': Timestamp.fromDate(today),
          });
        } else if (difference > 1 || currentStreak == 0) {
          transaction.update(userRef, {
            'streak': 1,
            'lastListenDate': Timestamp.fromDate(today),
          });
        }
      });
    } catch (e) {
      debugPrint("Streak Transaction Error: $e");
    }
  }

  void _recordListenToFirestore(String id, bool isEpisode,
      {String? parentSermonId}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    unawaited(_firestore.collection('listens').add({
      'contentId': id,
      'parentSermonId': parentSermonId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'isEpisode': isEpisode,
    }));

    final sermonId = isEpisode ? parentSermonId : id;
    if (sermonId == null) return;

    DocumentReference sermonRef =
        _firestore.collection('sermons').doc(sermonId);

    _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sermonRef);
      if (!snapshot.exists) return;

      if (!isEpisode) {
        transaction.update(sermonRef, {'playCount': FieldValue.increment(1)});
      } else {
        List<dynamic> episodes = List.from(snapshot.get('episodes') ?? []);
        bool found = false;
        for (var e in episodes) {
          if (e['id'] == id) {
            e['playCount'] = (e['playCount'] ?? 0) + 1;
            found = true;
            break;
          }
        }
        if (found) {
          transaction.update(sermonRef, {
            'playCount': FieldValue.increment(1),
            'episodes': episodes,
          });
        }
      }
    }).catchError((e) {
      debugPrint("PlayCount Transaction Error: $e");
    });
  }

  // ================= CONTROLS =================

  void seek(Duration pos) => _audioService.player.seek(pos);

  void setSpeed(double speed) {
    _speed = speed;
    _audioService.player.setSpeed(speed);
    notifyListeners();
  }

  void cycleSpeed() {
    _speed = (_speed == 1.0)
        ? 1.5
        : (_speed == 1.5)
            ? 2.0
            : 1.0;
    _audioService.player.setSpeed(_speed);
    notifyListeners();
  }

  void playSermon(
      Sermon sermon, List<Sermon> currentList, PlaybackContext context,
      {bool resumeFromSavedPosition = false}) {
    if (sermon.audioUrl.isEmpty && sermon.messageType == MessageType.single) {
      return;
    }

    if (sermon.messageType == MessageType.series &&
        sermon.episodes.isNotEmpty) {
      final playableEpisodes =
          sermon.episodes.where((e) => e.audioUrl.isNotEmpty).toList();
      if (playableEpisodes.isEmpty) {
        return;
      }
      playEpisode(sermon, playableEpisodes.first, currentList, context,
          resumeFromSavedPosition: resumeFromSavedPosition);
      return;
    }

    _session = PlaybackSession(
        context: context,
        type: ContentType.single,
        originalList: List.from(currentList));
    _currentSermon = sermon;
    _currentEpisode = null;
    _handleNewPlay(sermon.id, isEpisode: false);

    final playableSermons =
        _session!.originalList.where((s) => s.audioUrl.isNotEmpty).toList();
    if (playableSermons.isEmpty) {
      return;
    }

    final children = playableSermons
        .map((s) => AudioSource.uri(
              Uri.parse(_convertToDirectLink(s.audioUrl)),
              tag: MediaItem(
                  id: s.id,
                  album: s.seriesTitle ?? "Rhemalize",
                  title: s.title,
                  artist: s.speaker,
                  artUri: Uri.parse(_resolveArtUrl(s.imageUrl))),
            ))
        .toList();

    final int index = playableSermons.indexWhere((s) => s.id == sermon.id);
    _executePlay(
      playlist: children,
      initialIndex: index >= 0 ? index : 0,
      resumeFromSavedPosition: resumeFromSavedPosition,
    );
  }

  void playEpisode(Sermon series, Episode episode, List<Sermon> currentList,
      PlaybackContext context,
      {bool resumeFromSavedPosition = false}) {
    if (episode.audioUrl.isEmpty) {
      return;
    }

    _session = PlaybackSession(
        context: context,
        type: ContentType.series,
        originalList: List.from(currentList));
    _currentSermon = series;
    _currentEpisode = episode;
    _handleNewPlay(episode.id, isEpisode: true, parentSermonId: series.id);

    final playableEpisodes =
        series.episodes.where((e) => e.audioUrl.isNotEmpty).toList();
    if (playableEpisodes.isEmpty) {
      return;
    }

    final children = playableEpisodes
        .map((e) => AudioSource.uri(
              Uri.parse(_convertToDirectLink(e.audioUrl)),
              tag: MediaItem(
                  id: e.id,
                  album: series.title,
                  title: e.title,
                  artist: e.speaker,
                  artUri:
                      Uri.parse(_resolveArtUrl(e.imageUrl, series.imageUrl))),
            ))
        .toList();

    final int index = playableEpisodes.indexWhere((e) => e.id == episode.id);
    _executePlay(
      playlist: children,
      initialIndex: index >= 0 ? index : 0,
      resumeFromSavedPosition: resumeFromSavedPosition,
    );
  }

  Future<void> _executePlay({
    required List<AudioSource> playlist,
    required int initialIndex,
    BuildContext? context, // Added context to show the SnackBar
    bool resumeFromSavedPosition = false,
  }) async {
    _showFullPlayer = true;
    _isBuffering = true;
    _lastError = null;
    notifyListeners();

    try {
      await _audioService.player.stop();

      // 1. Check for saved position
      final id = _currentEpisode?.id ?? _currentSermon?.id;
      final prefs = await SharedPreferences.getInstance();
      final savedMs = prefs.getInt('$_positionPrefix$id') ?? 0;
      final initialPosition = Duration(milliseconds: savedMs);

      final safeIndex = (initialIndex >= 0 && initialIndex < playlist.length)
          ? initialIndex
          : 0;

      // 2. Start from beginning initially
      await _audioService.player.setAudioSources(
        playlist,
        initialIndex: safeIndex,
        initialPosition:
            resumeFromSavedPosition ? initialPosition : Duration.zero,
      );

      await _audioService.player.setSpeed(_speed);
      await _audioService.play();

      // 3. If they have significant progress (more than 10s), offer to resume
      if (!resumeFromSavedPosition &&
          savedMs > 10000 &&
          context != null &&
          context.mounted) {
        _showResumeSnackBar(context, initialPosition);
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint("Audio Play Error: $e");
    } finally {
      _isBuffering = false;
      notifyListeners();
    }
  }

  void _showResumeSnackBar(BuildContext context, Duration position) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Continue from ${position.toString().split('.').first.padLeft(8, "0").substring(2)}?"),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: "RESUME",
          onPressed: () => seek(position),
        ),
      ),
    );
  }

  void togglePlayPause() =>
      _isPlaying ? _audioService.pause() : _audioService.play();
  void playNext() => _audioService.player.seekToNext();
  void playPrevious() => _audioService.player.seekToPrevious();

  void stop() {
    _stopPositionTracking();
    _audioService.stop();
    _currentSermon = null;
    _currentEpisode = null;
    _session = null;
    _isBuffering = false;
    _isPlaying = false;
    _lastTrackId = null;
    _pendingHistoryTrackId = null;
    _pendingHistorySermonId = null;
    _pendingHistoryIsEpisode = false;
    _pendingHistoryCommitted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPositionTracking();
    super.dispose();
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

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final normalized = url.trim().toLowerCase();
    return !normalized.contains('via.placeholder.com');
  }

  String _resolveArtUrl(String? primary, [String? secondary]) {
    if (_isValidImageUrl(primary)) return primary!.trim();
    if (_isValidImageUrl(secondary)) return secondary!.trim();
    return _fallbackArt;
  }

  String _convertToDirectLink(String? url) {
    if (url == null || !url.contains('drive.google.com')) return url ?? "";
    final regExp = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match != null
        ? 'https://drive.google.com/uc?export=download&id=${match.group(1)}'
        : url;
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
    final List<String>? savedOrder = prefs.getStringList(_playedOrderKey);
    if (savedIds != null) _playedIds.addAll(savedIds);
    if (savedOrder != null && savedOrder.isNotEmpty) {
      _playedOrder.addAll(savedOrder);
    } else if (savedIds != null) {
      _playedOrder.addAll(savedIds);
    }
    for (final id in _playedOrder) {
      final savedMs = prefs.getInt('$_positionPrefix$id');
      if (savedMs != null && savedMs > 0) {
        _resumePositions[id] = savedMs;
      }
    }
    final String? dateStr = prefs.getString(_lastListenKey);
    if (dateStr != null) _lastListenDate = DateTime.parse(dateStr);
    _lastResumableId = prefs.getString(_lastResumeKey);
    if (_lastResumableId != null) {
      final resumeMs = prefs.getInt('$_positionPrefix$_lastResumableId');
      if (resumeMs != null && resumeMs > 0) {
        _resumePositions[_lastResumableId!] = resumeMs;
      }
    }
    notifyListeners();
  }

  Future<void> _savePlayedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playedKey, _playedIds.toList());
    await prefs.setStringList(_playedOrderKey, _playedOrder);
  }

  Future<void> clearPlayedHistory() async {
    final idsToClear = <String>{
      ..._playedOrder,
      ..._resumePositions.keys,
      if (_lastResumableId != null) _lastResumableId!,
    };
    _playedIds.clear();
    _playedOrder.clear();
    _resumePositions.clear();
    _lastResumableId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playedKey);
    await prefs.remove(_playedOrderKey);
    await prefs.remove(_lastResumeKey);
    for (final id in idsToClear) {
      await prefs.remove('$_positionPrefix$id');
    }
    notifyListeners();
  }

  void clearLastError() {
    if (_lastError == null) return;
    _lastError = null;
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
      if (next != null) {
        playSermon(next, _session!.originalList, _session!.context);
      } else {
        stop();
      }
    }
  }
}



