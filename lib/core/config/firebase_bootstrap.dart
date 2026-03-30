import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/firebase_options.dart';

class FirebaseBootstrapResult {
  final bool isSuccess;
  final String? message;

  const FirebaseBootstrapResult({required this.isSuccess, this.message});

  const FirebaseBootstrapResult.success() : this(isSuccess: true);

  const FirebaseBootstrapResult.failure(String message)
    : this(isSuccess: false, message: message);
}

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult>? _inFlight;
  static FirebaseBootstrapResult? _lastResult;

  static Future<FirebaseBootstrapResult> ensureInitialized() {
    if (Firebase.apps.isNotEmpty) {
      const FirebaseBootstrapResult success = FirebaseBootstrapResult.success();
      _lastResult = success;
      return Future<FirebaseBootstrapResult>.value(success);
    }

    final Future<FirebaseBootstrapResult>? activeRequest = _inFlight;
    if (activeRequest != null) {
      return activeRequest;
    }

    final Future<FirebaseBootstrapResult> request = _initialize().whenComplete(
      () {
        _inFlight = null;
      },
    );
    _inFlight = request;
    return request;
  }

  static FirebaseBootstrapResult? get lastResult => _lastResult;

  static Future<FirebaseBootstrapResult> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      const FirebaseBootstrapResult success = FirebaseBootstrapResult.success();
      _lastResult = success;
      return success;
    } on UnsupportedError catch (error) {
      return _initializeWithNativeConfig(
        fallbackMessage:
            error.message?.toString() ??
            'Firebase is not configured for this build.',
      );
    } on FirebaseException catch (error) {
      final FirebaseBootstrapResult failure = FirebaseBootstrapResult.failure(
        _friendlyMessage(error),
      );
      _lastResult = failure;
      return failure;
    } catch (error) {
      final FirebaseBootstrapResult failure = FirebaseBootstrapResult.failure(
        'Firebase initialization failed. Check your Firebase configuration before using phone authentication.',
      );
      _lastResult = failure;
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $error');
      }
      return failure;
    }
  }

  static Future<FirebaseBootstrapResult> _initializeWithNativeConfig({
    required String fallbackMessage,
  }) async {
    try {
      await Firebase.initializeApp();
      const FirebaseBootstrapResult success = FirebaseBootstrapResult.success();
      _lastResult = success;
      return success;
    } on FirebaseException catch (error) {
      final FirebaseBootstrapResult failure = FirebaseBootstrapResult.failure(
        _missingConfigMessage(error, fallbackMessage: fallbackMessage),
      );
      _lastResult = failure;
      return failure;
    } catch (error) {
      final FirebaseBootstrapResult failure = FirebaseBootstrapResult.failure(
        _missingConfigMessage(null, fallbackMessage: fallbackMessage),
      );
      _lastResult = failure;
      if (kDebugMode) {
        debugPrint('Firebase native initialization error: $error');
      }
      return failure;
    }
  }

  static String _friendlyMessage(FirebaseException error) {
    final String code = error.code.trim();
    switch (code) {
      case 'duplicate-app':
        return 'Firebase was initialized more than once for this app.';
      case 'invalid-api-key':
      case 'invalid-credential':
        return 'Firebase configuration is invalid. Verify your Firebase app options.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Firebase initialization failed. Verify your Firebase configuration.';
    }
  }

  static String _missingConfigMessage(
    FirebaseException? error, {
    required String fallbackMessage,
  }) {
    final String? nativeFileHint = switch (defaultTargetPlatform) {
      TargetPlatform.iOS =>
        'Add `ios/Runner/GoogleService-Info.plist`, or run `flutterfire configure`.',
      TargetPlatform.android =>
        'Add `android/app/google-services.json`, or run `flutterfire configure`.',
      _ => null,
    };

    final String message = nativeFileHint == null
        ? fallbackMessage
        : 'Firebase configuration is missing for this build. $nativeFileHint';

    final String firebaseMessage = error?.message?.trim() ?? '';
    if (firebaseMessage.isEmpty) {
      return message;
    }

    return '$message\n$firebaseMessage';
  }
}
