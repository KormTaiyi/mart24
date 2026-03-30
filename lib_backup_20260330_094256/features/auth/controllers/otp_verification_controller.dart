import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mart24/features/auth/services/phone_auth_service.dart';

sealed class OtpVerificationEvent {}

class OtpVerificationSucceeded extends OtpVerificationEvent {
  final String phoneNumber;

  OtpVerificationSucceeded(this.phoneNumber);
}

class OtpVerificationController extends ChangeNotifier {
  OtpVerificationController({
    required this.phoneNumber,
    PhoneAuthService? phoneAuthService,
  }) : _phoneAuthService = phoneAuthService ?? PhoneAuthService.instance;

  static const int otpLength = 6;
  static const Duration resendCooldown = Duration(seconds: 30);

  final String phoneNumber;
  final PhoneAuthService _phoneAuthService;
  final StreamController<OtpVerificationEvent> _events =
      StreamController<OtpVerificationEvent>.broadcast();

  Stream<OtpVerificationEvent> get events => _events.stream;

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _hasCompletedAuthentication = false;
  String _otpCode = '';
  String _verificationId = '';
  String? _errorMessage;
  String? _statusMessage;
  int? _resendToken;
  int _secondsUntilResend = 0;
  Timer? _timer;

  bool get isSendingCode => _isSendingCode;
  bool get isVerifyingCode => _isVerifyingCode;
  bool get isBusy => _isSendingCode || _isVerifyingCode;
  String get otpCode => _otpCode;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String get verificationId => _verificationId;
  bool get hasCodeBeenSent => _verificationId.trim().isNotEmpty;
  int get secondsUntilResend => _secondsUntilResend;
  bool get canResend => !isBusy && _secondsUntilResend == 0;
  bool get canVerify => !isBusy && _otpCode.length == otpLength;

  Future<void> initialize() async {
    await sendCode();
  }

  Future<void> sendCode({bool isResend = false}) async {
    if (isBusy || _hasCompletedAuthentication) {
      return;
    }

    _isSendingCode = true;
    _errorMessage = null;
    _statusMessage = isResend
        ? 'Sending a new code...'
        : 'Sending verification code...';
    notifyListeners();

    await _phoneAuthService.startVerification(
      phoneNumber: phoneNumber,
      forceResendingToken: isResend ? _resendToken : null,
      onCodeSent: (PhoneOtpSession session) {
        _verificationId = session.verificationId;
        _resendToken = session.resendToken;
        _statusMessage =
            'Code sent to ${PhoneAuthService.maskPhoneNumber(session.phoneNumber)}';
        _isSendingCode = false;
        _startResendCooldown();
        notifyListeners();
      },
      onFailed: (PhoneAuthFailure failure) {
        _isSendingCode = false;
        _errorMessage = failure.message;
        _statusMessage = null;
        if (failure.type == PhoneAuthFailureType.otpExpired) {
          _secondsUntilResend = 0;
        }
        notifyListeners();
      },
      onAutoVerified: (PhoneAuthSignInResult result) async {
        _isSendingCode = false;
        _isVerifyingCode = false;

        if (!result.isSuccess) {
          _errorMessage = result.message;
          _statusMessage = null;
          notifyListeners();
          return;
        }

        _otpCode = _sanitizeDigits(result.smsCode ?? _otpCode);
        _statusMessage = 'Phone number verified automatically.';
        notifyListeners();
        _emitSuccess(result.phoneNumber);
      },
      onCodeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        notifyListeners();
      },
    );
  }

  Future<void> updateOtpCode(String value) async {
    final String sanitized = _sanitizeDigits(value);
    if (_otpCode == sanitized) {
      return;
    }

    _otpCode = sanitized.length > otpLength
        ? sanitized.substring(0, otpLength)
        : sanitized;
    _errorMessage = null;
    notifyListeners();

    if (_otpCode.length == otpLength) {
      await verifyCode();
    }
  }

  Future<void> verifyCode() async {
    if (_hasCompletedAuthentication || isBusy) {
      return;
    }

    if (_verificationId.trim().isEmpty) {
      _errorMessage =
          'This verification session is not ready yet. Please request a new code.';
      notifyListeners();
      return;
    }

    if (_otpCode.length != otpLength) {
      _errorMessage = 'Enter the 6-digit code to continue.';
      notifyListeners();
      return;
    }

    _isVerifyingCode = true;
    _errorMessage = null;
    _statusMessage = 'Verifying code...';
    notifyListeners();

    final PhoneAuthSignInResult result = await _phoneAuthService.verifyOtp(
      verificationId: _verificationId,
      smsCode: _otpCode,
      phoneNumber: phoneNumber,
    );

    _isVerifyingCode = false;

    if (!result.isSuccess) {
      _errorMessage = result.message;
      if (result.failureType == PhoneAuthFailureType.incorrectOtp ||
          result.failureType == PhoneAuthFailureType.otpExpired) {
        _otpCode = '';
      }
      if (result.failureType == PhoneAuthFailureType.otpExpired) {
        _secondsUntilResend = 0;
        _timer?.cancel();
      }
      notifyListeners();
      return;
    }

    _statusMessage = 'Phone number verified.';
    notifyListeners();
    _emitSuccess(result.phoneNumber);
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _emitSuccess(String verifiedPhoneNumber) {
    if (_hasCompletedAuthentication) {
      return;
    }

    _hasCompletedAuthentication = true;
    _events.add(OtpVerificationSucceeded(verifiedPhoneNumber));
  }

  void _startResendCooldown() {
    _timer?.cancel();
    _secondsUntilResend = resendCooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsUntilResend <= 1) {
        _secondsUntilResend = 0;
        timer.cancel();
      } else {
        _secondsUntilResend -= 1;
      }
      notifyListeners();
    });
  }

  String _sanitizeDigits(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in value.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events.close();
    super.dispose();
  }
}
