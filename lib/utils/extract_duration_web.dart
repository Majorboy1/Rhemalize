import 'dart:html' as html;
import 'dart:async';

/// Web implementation — uses the browser's native AudioElement,
/// which is the most reliable way to get audio duration on web.
Future<Duration?> platformExtractDuration(String audioUrl) async {
  if (audioUrl.isEmpty) return null;

  final completer = Completer<Duration?>();
  final audio = html.AudioElement()
    ..src = audioUrl
    ..preload = 'metadata';

  audio.onLoadedMetadata.listen((_) {
    if (!completer.isCompleted) {
      final seconds = audio.duration;
      if (seconds.isFinite && seconds > 0) {
        completer.complete(
          Duration(milliseconds: (seconds * 1000).round()),
        );
      } else {
        completer.complete(null);
      }
    }
    audio.remove();
  });

  audio.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
    audio.remove();
  });

  // Timeout safety
  Timer(const Duration(seconds: 20), () {
    if (!completer.isCompleted) {
      completer.complete(null);
      audio.remove();
    }
  });

  return completer.future;
}
