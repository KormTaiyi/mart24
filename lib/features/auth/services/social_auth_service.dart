import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  SocialAuthService._();

  static Future<SocialAuthResult> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final GoogleSignInAccount? account = await googleSignIn.signIn();

    if (account == null) {
      throw const SocialAuthException('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication authData = await account.authentication;
    final String? idToken = authData.idToken;
    final String? accessToken = authData.accessToken;

    if (idToken == null && accessToken == null) {
      throw const SocialAuthException(
        'Unable to get Google auth tokens. Check Google Sign-In setup.',
      );
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

  const SocialAuthResult({
    this.identifier,
    this.idToken,
    this.accessToken,
  });
}
