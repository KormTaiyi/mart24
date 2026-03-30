import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Phone authentication is configured only for Android and iOS in this app.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Phone authentication is available only on Android and iOS real devices. Current platform: $defaultTargetPlatform.',
        );
    }
  }

  static FirebaseOptions get android {
    final FirebaseOptions? options = _android;
    if (options != null) {
      return options;
    }

    throw UnsupportedError(_androidSetupMessage);
  }

  static FirebaseOptions get ios {
    final FirebaseOptions? options = _ios;
    if (options != null) {
      return options;
    }

    throw UnsupportedError(_iosSetupMessage);
  }

  static final FirebaseOptions? _android = _buildAndroidOptions();
  static final FirebaseOptions? _ios = _buildIosOptions();

  static FirebaseOptions? _buildAndroidOptions() {
    if (!_hasRequiredValues(const [
      _androidApiKey,
      _androidAppId,
      _messagingSenderId,
      _projectId,
    ])) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _emptyToNull(_androidStorageBucket),
    );
  }

  static FirebaseOptions? _buildIosOptions() {
    if (!_hasRequiredValues(const [
      _iosApiKey,
      _iosAppId,
      _messagingSenderId,
      _projectId,
    ])) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _iosApiKey,
      appId: _iosAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _emptyToNull(_iosStorageBucket),
      iosBundleId: _emptyToNull(_iosBundleId),
      iosClientId: _emptyToNull(_iosClientId),
    );
  }

  static bool _hasRequiredValues(List<String> values) {
    for (final String value in values) {
      if (value.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  static String? _emptyToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static const String _androidSetupMessage =
      'Firebase Android options are missing. Add `android/app/google-services.json`, '
      'run `flutterfire configure`, or provide '
      'FIREBASE_ANDROID_API_KEY, FIREBASE_ANDROID_APP_ID, FIREBASE_MESSAGING_SENDER_ID, '
      'and FIREBASE_PROJECT_ID via --dart-define.';

  static const String _iosSetupMessage =
      'Firebase iOS options are missing. Add `ios/Runner/GoogleService-Info.plist`, '
      'run `flutterfire configure`, or provide '
      'FIREBASE_IOS_API_KEY, FIREBASE_IOS_APP_ID, FIREBASE_MESSAGING_SENDER_ID, '
      'FIREBASE_PROJECT_ID, and FIREBASE_IOS_BUNDLE_ID via --dart-define.';

  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
  );

  static const String _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );
  static const String _iosClientId = String.fromEnvironment(
    'FIREBASE_IOS_CLIENT_ID',
  );
  static const String _iosStorageBucket = String.fromEnvironment(
    'FIREBASE_IOS_STORAGE_BUCKET',
  );

  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
}
