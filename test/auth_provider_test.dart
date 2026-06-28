import 'package:flutter_test/flutter_test.dart';
import 'package:rhemalize/providers/auth_provider.dart';

void main() {
  test('Android Google sign-in configuration uses google-services defaults',
      () {
    final config = AuthProvider.getGoogleSignInConfiguration(forWeb: false);

    expect(config.clientId, isNull);
    expect(config.serverClientId, isNull);
    expect(config.scopes, contains('email'));
  });

  test(
      'Web Google sign-in configuration keeps the client id unset and uses the server client id',
      () {
    final config = AuthProvider.getGoogleSignInConfiguration(forWeb: true);

    expect(config.clientId, isNull);
    expect(
        config.serverClientId,
        equals(
            '653124289726-mma5hdf4i1ml661d7449be13p8endvh2.apps.googleusercontent.com'));
  });
}
