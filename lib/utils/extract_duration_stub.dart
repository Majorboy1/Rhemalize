import 'package:just_audio/just_audio.dart';

/// Stub implementation (non-web platforms).
/// Uses just_audio to extract audio duration.
Future<Duration?> platformExtractDuration(String audioUrl) async {
  if (audioUrl.isEmpty) return null;

  final player = AudioPlayer();
  try {
    await player
        .setAudioSource(AudioSource.uri(Uri.parse(audioUrl)))
        .timeout(const Duration(seconds: 15));

    await player.play();

    await player.playerStateStream
        .firstWhere(
          (state) => state.processingState == ProcessingState.ready,
        )
        .timeout(const Duration(seconds: 15));

    final dur = player.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      await player.stop();
      return dur;
    }

    await player.stop();
    return null;
  } catch (_) {
    try {
      final dur = player.duration;
      if (dur != null && dur.inMilliseconds > 0) return dur;
      final d = await player.durationStream.firstWhere(
        (d) => d != null && d.inMilliseconds > 0,
        orElse: () => null,
      );
      return d;
    } catch (_) {
      return null;
    }
  } finally {
    player.dispose();
  }
}
