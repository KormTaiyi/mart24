import 'package:google_sign_in/google_sign_in.dart';
import 'package:mart24/core/config/google_auth_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  SocialAuthService._();

  static final GoogleSignIn _googleSignIn =
      GoogleAuthConfig.buildGoogleSignIn();

  static Future<SocialAuthResult> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      throw const SocialAuthException('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication authData = await account.authentication;
    final String? idToken = authData.idToken?.trim();
    final String? accessToken = authData.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw SocialAuthException(_googleIdTokenError());
    }

    return SocialAuthResult(
      identifier: account.email.isNotEmpty ? account.email : account.id,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<SocialAuthResult> signInWithApple() async {
    final bool isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw const SocialAuthException(
        'Apple Sign-In is not available on this device.',
      );
    }

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

    final String? idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw const SocialAuthException('Unable to get Apple identity token.');
    }

    final String identifier =
        (appleCredential.email ?? appleCredential.userIdentifier ?? '').trim();
    return SocialAuthResult(identifier: identifier, idToken: idToken);
  }

  static String _googleIdTokenError() {
    final bool hasServerClientId =
        (GoogleAuthConfig.serverClientId ?? '').isNotEmpty;
    if (!hasServerClientId) {
      return 'Google Sign-In is missing server client ID. '
          '${GoogleAuthConfig.configurationHint()}';
    }

    return 'Google sign-in succeeded but did not return an ID token. '
        'Check OAuth client settings and SHA fingerprints in Google Console. '
        '${GoogleAuthConfig.configurationHint()}';
  }
}

class SocialAuthException implements Exception {
  final String message;

  const SocialAuthException(this.message);

  @override
  String toString() => message;
}

class SocialAuthResult {
  final String? identifier;
  final String? idToken;
  final String? accessToken;

  const SocialAuthResult({this.identifier, this.idToken, this.accessToken});
}
