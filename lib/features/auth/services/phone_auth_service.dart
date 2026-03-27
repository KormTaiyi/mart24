import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/network/models/auth_tokens.dart';
import 'package:mart24/core/storage/app_storage.dart';
import 'package:mart24/core/storage/token_storage.dart';
import 'package:mart24/features/auth/services/auth_service.dart';

class PhoneOtpRequestResult {
  final bool isSuccess;
  final String? message;
  final String verificationId;
  final String phoneE164;
  final int? resendToken;

  const PhoneOtpRequestResult({
    required this.isSuccess,
    required this.verificationId,
    required this.phoneE164,
    this.resendToken,
    this.message,
  });

  factory PhoneOtpRequestResult.failure(String message) {
    return PhoneOtpRequestResult(
      isSuccess: false,
      verificationId: '',
      phoneE164: '',
      message: message,
    );
  }
}

class PhoneOtpVerifyResult {
  final bool isSuccess;
  final String? message;

  const PhoneOtpVerifyResult({required this.isSuccess, this.message});

  factory PhoneOtpVerifyResult.failure(String message) {
    return PhoneOtpVerifyResult(isSuccess: false, message: message);
  }
}

class PhoneAuthService {
  PhoneAuthService._();

  static const String _lastPhoneStorageKey = 'auth.lastPhoneE164.v1';
  static final ApiClient _client = ApiClient.instance;

  static Future<PhoneOtpRequestResult> sendOtp({
    required String rawPhone,
    int? forceResendingToken,
  }) async {
    final String? phoneE164 = _toE164(rawPhone);
    if (phoneE164 == null) {
      return PhoneOtpRequestResult.failure(
        'Please enter a valid phone number.',
      );
    }

    try {
      final dynamic response = await _client.post<dynamic>(
        ApiEndpoints.sendOtp,
        data: {
          'phone': phoneE164,
          'phoneNumber': phoneE164,
          'forceResendingToken': forceResendingToken,
        },
      );

      final Map<String, dynamic> payload = _extractPayload(response);
      final String verificationId = _firstString(payload, const [
        'verificationId',
        'verification_id',
        'requestId',
        'request_id',
      ]);
      final int? resendToken = _readInt(payload['resendToken']);

      if (verificationId.isEmpty) {
        final String message =
            (payload['message'] ?? '').toString().trim().isNotEmpty
            ? payload['message'].toString()
            : 'OTP sent but verification data is missing from API response.';
        return PhoneOtpRequestResult.failure(message);
      }

      await saveLastUsedPhone(phoneE164);

      return PhoneOtpRequestResult(
        isSuccess: true,
        verificationId: verificationId,
        phoneE164: phoneE164,
        resendToken: resendToken,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return PhoneOtpRequestResult.failure(
          'OTP service endpoint was not found (404). Please verify backend route for send OTP.',
        );
      }
      return PhoneOtpRequestResult.failure(error.message);
    } catch (_) {
      return PhoneOtpRequestResult.failure('Unable to send OTP right now.');
    }
  }

  static Future<PhoneOtpVerifyResult> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.trim().isEmpty) {
      return PhoneOtpVerifyResult.failure('Missing verification session.');
    }

    if (smsCode.trim().length < 6) {
      return PhoneOtpVerifyResult.failure('Invalid OTP code.');
    }

    try {
      final dynamic response = await _client.post<dynamic>(
        ApiEndpoints.verifyOtp,
        data: {
          'verificationId': verificationId,
          'verification_id': verificationId,
          'otp': smsCode,
          'smsCode': smsCode,
          'code': smsCode,
        },
      );

      final Map<String, dynamic> payload = _extractPayload(response);
      final AuthTokens tokens = _extractTokens(payload);
      if (tokens.isValid) {
        await TokenStorage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.hasRefreshToken ? tokens.refreshToken : null,
        );
      }

      return const PhoneOtpVerifyResult(isSuccess: true);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return PhoneOtpVerifyResult.failure(
          'OTP verify endpoint was not found (404). Please verify backend route for verify OTP.',
        );
      }
      return PhoneOtpVerifyResult.failure(error.message);
    } catch (_) {
      return PhoneOtpVerifyResult.failure(
        'Unable to verify OTP right now. Please try again.',
      );
    }
  }

  static String? _toE164(String rawPhone) {
    final String trimmed = rawPhone.trim();
    final String digits = AuthService.normalizePhoneDigits(rawPhone);

    if (digits.length < 8 || digits.length > 15) {
      return null;
    }

    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    // Accept international prefix entered as 00... and normalize to +...
    if (trimmed.startsWith('00') && digits.startsWith('00')) {
      final String withoutZeros = digits.substring(2);
      if (withoutZeros.length < 8 || withoutZeros.length > 15) {
        return null;
      }
      return '+$withoutZeros';
    }

    // Country-neutral fallback: treat numeric input as already including country code.
    return '+$digits';
  }

  static Map<String, dynamic> _extractPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      final Object? data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }

    return const <String, dynamic>{};
  }

  static AuthTokens _extractTokens(Map<String, dynamic> payload) {
    if (payload['tokens'] is Map<String, dynamic>) {
      return AuthTokens.fromJson(payload['tokens'] as Map<String, dynamic>);
    }

    return AuthTokens.fromJson(payload);
  }

  static String _firstString(Map<String, dynamic> payload, List<String> keys) {
    for (final String key in keys) {
      final String value = (payload[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
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

  /// Optional helper for backends that expose a single phone-login endpoint
  /// (e.g. `/auth/phone/login/firebase`) instead of split send/verify OTP routes.
  static Future<Map<String, dynamic>> phoneLoginFirebase({
    required String phoneNumber,
    required String idToken,
  }) async {
    final dynamic response = await _client.post<dynamic>(
      ApiEndpoints.phoneLoginFirebase,
      data: {
        'phoneNumber': phoneNumber,
        'phone': phoneNumber,
        'idToken': idToken,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }

    return <String, dynamic>{};
  }
}
