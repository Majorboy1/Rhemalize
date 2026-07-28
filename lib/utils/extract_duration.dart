// Conditional export: uses dart:html AudioElement on web,
// just_audio on other platforms (Android, iOS, macOS, etc.)
export 'extract_duration_stub.dart'
    if (dart.library.html) 'extract_duration_web.dart';
