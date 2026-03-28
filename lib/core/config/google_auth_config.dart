import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String _serverClientIdValue = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String? get serverClientId {
    final v = _serverClientIdValue.trim();
    return v.isEmpty ? null : v;
  }

  static GoogleSignIn buildGoogleSignIn() {
    
    return GoogleSignIn(
      // serverClientId: serverClientId,
      serverClientId: '747570315218-dfqfejpd1ns1dole166m5th8bihor171.apps.googleusercontent.com',
      scopes: const <String>['email', 'profile'],
    );
  }

  static String configurationHint() {
    return 'Set --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>';
  }
}
