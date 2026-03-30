import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/config/app_environment.dart';
import 'package:mart24/core/config/firebase_bootstrap.dart';
import 'package:mart24/core/storage/app_storage.dart';
import 'package:mart24/features/auth/services/api/auth_api_service.dart';
import 'package:mart24/features/auth/services/auth_service.dart';

enum PhoneAuthFailureType {
  configuration,
  unsupportedPlatform,
  invalidPhoneNumber,
  network,
  otpExpired,
  incorrectOtp,
  tooManyRequests,
  quotaExceeded,
  appVerificationFailed,
  cancelled,
  unknown,
}

class PhoneAuthFailure {
  final PhoneAuthFailureType type;
  final String message;

  const PhoneAuthFailure({required this.type, required this.message});
}

class PhoneOtpSession {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const PhoneOtpSession({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });
}

class PhoneAuthSignInResult {
  final bool isSuccess;
  final String phoneNumber;
  final String? message;
  final String? smsCode;
  final bool syncedWithBackend;
  final PhoneAuthFailureType? failureType;

  const PhoneAuthSignInResult({
    required this.isSuccess,
    required this.phoneNumber,
    this.message,
    this.smsCode,
    this.syncedWithBackend = false,
    this.failureType,
  });

  factory PhoneAuthSignInResult.success({
    required String phoneNumber,
    String? smsCode,
    bool syncedWithBackend = false,
  }) {
    return PhoneAuthSignInResult(
      isSuccess: true,
      phoneNumber: phoneNumber,
      smsCode: smsCode,
      syncedWithBackend: syncedWithBackend,
    );
  }

  factory PhoneAuthSignInResult.failure(PhoneAuthFailure failure) {
    return PhoneAuthSignInResult(
      isSuccess: false,
      phoneNumber: '',
      message: failure.message,
      failureType: failure.type,
    );
  }
}

class PhoneAuthService {
  PhoneAuthService._({
    FirebaseAuth? firebaseAuth,
    AuthApiService? authApiService,
  }) : _firebaseAuthOverride = firebaseAuth,
       _authApiService = authApiService ?? AuthApiService();

  static final PhoneAuthService instance = PhoneAuthService._();
  static const String _lastPhoneStorageKey = 'auth.lastPhoneE164.v1';

  final FirebaseAuth? _firebaseAuthOverride;
  final AuthApiService _authApiService;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

  Future<PhoneAuthFailure?> ensureReady() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const PhoneAuthFailure(
        type: PhoneAuthFailureType.unsupportedPlatform,
        message:
            'Phone sign-in is currently available only on Android and iOS real devices.',
      );
    }

    final FirebaseBootstrapResult firebaseResult =
        await FirebaseBootstrap.ensureInitialized();
    if (!firebaseResult.isSuccess) {
      return PhoneAuthFailure(
        type: PhoneAuthFailureType.configuration,
        message:
            firebaseResult.message ??
            'Firebase is not configured for phone authentication.',
      );
    }

    return null;
  }

  Future<void> startVerification({
    required String phoneNumber,
    required void Function(PhoneOtpSession session) onCodeSent,
    required void Function(PhoneAuthFailure failure) onFailed,
    required FutureOr<void> Function(PhoneAuthSignInResult result)
    onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    final PhoneAuthFailure? readinessFailure = await ensureReady();
    if (readinessFailure != null) {
      onFailed(readinessFailure);
      return;
    }

    final String? normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (normalizedPhone == null) {
      onFailed(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.invalidPhoneNumber,
          message: 'Enter a valid phone number with the correct country code.',
        ),
      );
      return;
    }

    await saveLastUsedPhone(normalizedPhone);

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final PhoneAuthSignInResult result = await _signInWithCredential(
            credential,
            phoneNumber: normalizedPhone,
          );
          await onAutoVerified(result);
        },
        verificationFailed: (FirebaseAuthException error) {
          onFailed(_mapFirebaseAuthException(error));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(
            PhoneOtpSession(
              verificationId: verificationId,
              phoneNumber: normalizedPhone,
              resendToken: resendToken,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onCodeAutoRetrievalTimeout?.call(verificationId);
        },
      );
    } on FirebaseAuthException catch (error) {
      onFailed(_mapFirebaseAuthException(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Phone verification failed: $error');
      }

      onFailed(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.unknown,
          message: 'Unable to send the verification code right now.',
        ),
      );
    }
  }

  Future<PhoneAuthSignInResult> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final PhoneAuthFailure? readinessFailure = await ensureReady();
    if (readinessFailure != null) {
      return PhoneAuthSignInResult.failure(readinessFailure);
    }

    if (verificationId.trim().isEmpty) {
      return PhoneAuthSignInResult.failure(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.otpExpired,
          message:
              'This verification session has expired. Please request a new code.',
        ),
      );
    }

    if (smsCode.trim().length < 6) {
      return PhoneAuthSignInResult.failure(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.incorrectOtp,
          message: 'Enter the 6-digit code to continue.',
        ),
      );
    }

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      return await _signInWithCredential(
        credential,
        phoneNumber: phoneNumber,
        smsCode: smsCode.trim(),
      );
    } on FirebaseAuthException catch (error) {
      return PhoneAuthSignInResult.failure(_mapFirebaseAuthException(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('OTP verification failed: $error');
      }

      return PhoneAuthSignInResult.failure(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.unknown,
          message: 'Unable to verify the code right now. Please try again.',
        ),
      );
    }
  }

  Future<PhoneAuthSignInResult> _signInWithCredential(
    PhoneAuthCredential credential, {
    required String phoneNumber,
    String? smsCode,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final String resolvedPhoneNumber =
          userCredential.user?.phoneNumber?.trim().isNotEmpty == true
          ? userCredential.user!.phoneNumber!.trim()
          : phoneNumber;

      await saveLastUsedPhone(resolvedPhoneNumber);

      bool syncedWithBackend = false;
      if (!AppEnvironment.useMockApi) {
        syncedWithBackend = await _syncBackendSession(
          phoneNumber: resolvedPhoneNumber,
          user: userCredential.user,
        );
      }

      return PhoneAuthSignInResult.success(
        phoneNumber: resolvedPhoneNumber,
        smsCode: smsCode ?? credential.smsCode,
        syncedWithBackend: syncedWithBackend,
      );
    } on FirebaseAuthException catch (error) {
      return PhoneAuthSignInResult.failure(_mapFirebaseAuthException(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Credential sign-in failed: $error');
      }

      return PhoneAuthSignInResult.failure(
        const PhoneAuthFailure(
          type: PhoneAuthFailureType.unknown,
          message:
              'We verified your code but could not finish signing you in. Please try again.',
        ),
      );
    }
  }

  Future<bool> _syncBackendSession({
    required String phoneNumber,
    required User? user,
  }) async {
    if (user == null) {
      return false;
    }

    try {
      final String? idToken = await user.getIdToken(true);
      if (idToken == null || idToken.trim().isEmpty) {
        return false;
      }

      final result = await _authApiService.phoneLoginFirebase(
        phoneNumber: phoneNumber,
        idToken: idToken.trim(),
      );
      return result?.hasAccessToken == true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Phone auth backend sync skipped: $error');
      }
      return false;
    }
  }

  PhoneAuthFailure _mapFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.invalidPhoneNumber,
          message:
              'That phone number is invalid. Check the country code and try again.',
        );
      case 'network-request-failed':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.network,
          message: 'No internet connection. Check your network and try again.',
        );
      case 'quota-exceeded':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.quotaExceeded,
          message:
              'Too many OTP attempts were made for this project. Please wait and try again later.',
        );
      case 'too-many-requests':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.tooManyRequests,
          message:
              'Too many requests were made from this device. Please wait before trying again.',
        );
      case 'session-expired':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.otpExpired,
          message: 'This code has expired. Request a new code and try again.',
        );
      case 'invalid-verification-code':
      case 'missing-verification-code':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.incorrectOtp,
          message: 'The code you entered is incorrect. Please try again.',
        );
      case 'invalid-verification-id':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.otpExpired,
          message:
              'This verification session is no longer valid. Request a new code.',
        );
      case 'app-not-authorized':
      case 'operation-not-allowed':
      case 'captcha-check-failed':
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.appVerificationFailed,
          message:
              'This build is not fully configured for Firebase phone authentication. Check your Firebase and platform setup.',
        );
      case 'web-context-cancelled':
        return const PhoneAuthFailure(
          type: PhoneAuthFailureType.cancelled,
          message: 'Verification was cancelled before it could finish.',
        );
      default:
        final String fallbackMessage = error.message?.trim() ?? '';
        return PhoneAuthFailure(
          type: PhoneAuthFailureType.unknown,
          message: fallbackMessage.isNotEmpty
              ? fallbackMessage
              : 'Something went wrong while verifying your phone number.',
        );
    }
  }

  static String? normalizePhoneNumber(String rawPhone) {
    final String trimmed = rawPhone.trim();
    final String digits = AuthService.normalizePhoneDigits(rawPhone);

    if (digits.length < 8 || digits.length > 15) {
      return null;
    }

    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    if (trimmed.startsWith('00') && digits.startsWith('00')) {
      final String withoutZeros = digits.substring(2);
      if (withoutZeros.length < 8 || withoutZeros.length > 15) {
        return null;
      }
      return '+$withoutZeros';
    }

    return '+$digits';
  }

  static String maskPhoneNumber(String phoneNumber) {
    final String normalized = normalizePhoneNumber(phoneNumber) ?? phoneNumber;
    if (normalized.length <= 6) {
      return normalized;
    }

    final String prefix = normalized.substring(0, 4);
    final String suffix = normalized.substring(normalized.length - 2);
    return '$prefix ${List<String>.filled(normalized.length - 6, '•').join()} $suffix';
  }

  static Future<String?> getLastUsedPhone() async {
    final String? value = await AppStorage.getString(_lastPhoneStorageKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static Future<void> saveLastUsedPhone(String phone) async {
    final String normalized = phone.trim();
    if (normalized.isEmpty) {
      return;
    }
    await AppStorage.setString(_lastPhoneStorageKey, normalized);
  }
}
