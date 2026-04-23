import 'package:flutter_test/flutter_test.dart';
import 'package:rhemalize/utils/app_logger.dart';

void main() {
  test('AppLogger.debug does not throw', () {
    expect(() => AppLogger.debug('release-safe log'), returnsNormally);
  });
}
