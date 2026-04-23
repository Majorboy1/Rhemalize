import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | error: $error');
    }

    debugPrint(buffer.toString());
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
