import 'extract_duration.dart';

/// Formats a [Duration] into a human-readable string.
///
/// Examples:
/// - `Duration(minutes: 45, seconds: 18)` → `"45:18"`
/// - `Duration(hours: 1, minutes: 12, seconds: 34)` → `"1:12:34"`
/// - `Duration(minutes: 8, seconds: 5)` → `"08:05"`
String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  if (totalSeconds <= 0) return '0:00';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = totalSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Extracts the duration of an audio file from [audioUrl].
///
/// On **web**: uses `dart:html` `AudioElement` directly (browser-native, reliable).
/// On **mobile/desktop**: uses `just_audio` `AudioPlayer`.
///
/// Returns `null` if the duration could not be determined.
Future<Duration?> extractDurationFromUrl(String audioUrl) {
  return platformExtractDuration(audioUrl);
}
