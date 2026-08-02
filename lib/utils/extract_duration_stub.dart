import 'dart:async';
import 'package:just_audio/just_audio.dart';

/// Stub implementation (non-web platforms).
/// Uses just_audio to extract audio duration.
///
/// IMPORTANT: `just_audio_background` only supports a single `AudioPlayer`
/// instance. The app's main player (`AudioService`) is already registered, so
/// creating a second player here makes `just_audio_background` throw
/// `PlatformException(... supports only a single player instance ...)`.
///
/// Previously that exception fell into a fallback that awaited
/// `durationStream.firstWhere(...)` with no timeout, so the player never
/// became ready and the upload flow hung forever at 100%.
///
/// We now treat any failure (including the single-player restriction) as
/// "duration unknown" and return `null` quickly, with a hard timeout so the
/// caller can never be blocked. This lets uploads complete even when the
/// duration can't be measured.
Future<Duration?> platformExtractDuration(String audioUrl) async {
  if (audioUrl.isEmpty) return null;

  final player = AudioPlayer();
  try {
    return await _loadDuration(player, audioUrl)
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    // Covers the just_audio_background single-player restriction, network
    // failures, and timeouts. Duration is best-effort only.
    return null;
  } finally {
    // Always release the player so the main player keeps working afterwards.
    player.dispose();
  }
}

Future<Duration?> _loadDuration(AudioPlayer player, String audioUrl) async {
  await player
      .setAudioSource(AudioSource.uri(Uri.parse(audioUrl)))
      .timeout(const Duration(seconds: 15));

  await player
      .playerStateStream
      .firstWhere((state) => state.processingState == ProcessingState.ready)
      .timeout(const Duration(seconds: 15));

  final dur = player.duration;
  if (dur != null && dur.inMilliseconds > 0) return dur;
  return null;
}
