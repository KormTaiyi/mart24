import 'package:flutter/foundation.dart';
import 'package:mart24/features/auth/services/device_phone_hint_service.dart';
import 'package:mart24/features/auth/services/phone_auth_service.dart';

class PhoneNumberAuthController extends ChangeNotifier {
  PhoneNumberAuthController({PhoneAuthService? phoneAuthService})
    : _phoneAuthService = phoneAuthService ?? PhoneAuthService.instance;

  final PhoneAuthService _phoneAuthService;

  bool _isCheckingDevicePhone = false;
  bool _isSubmitting = false;
  bool _showManualEntry = false;
  String? _errorMessage;
  String? _infoMessage;
  String? _initialPhoneNumber;

  bool get isCheckingDevicePhone => _isCheckingDevicePhone;
  bool get isSubmitting => _isSubmitting;
  bool get showManualEntry => _showManualEntry;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  String? get initialPhoneNumber => _initialPhoneNumber;
  bool get canRetryPhoneHint =>
      DevicePhoneHintService.isSupportedOnCurrentPlatform;

  Future<String?> initialize() async {
    _errorMessage = null;
    _infoMessage = null;
    _initialPhoneNumber = await PhoneAuthService.getLastUsedPhone();
    notifyListeners();

    if (!DevicePhoneHintService.isSupportedOnCurrentPlatform) {
      _showManualEntry = true;
      _infoMessage = _initialPhoneNumber == null
          ? 'Receive a verification code by SMS.'
          : 'Use your saved number or enter a different one.';
      notifyListeners();
      return null;
    }

    _isCheckingDevicePhone = true;
    _showManualEntry = false;
    _infoMessage = 'Checking this device for an available phone number...';
    notifyListeners();

    try {
      final String? hintedPhone =
          await DevicePhoneHintService.getPhoneNumberHint();
      final String? normalizedHint = hintedPhone == null
          ? null
          : PhoneAuthService.normalizePhoneNumber(hintedPhone);

      _isCheckingDevicePhone = false;

      if (normalizedHint != null) {
        _infoMessage = 'Using the phone number selected from this device.';
        notifyListeners();
        return normalizedHint;
      }

      if (hintedPhone != null && hintedPhone.trim().isNotEmpty) {
        _initialPhoneNumber = hintedPhone.trim();
        _infoMessage =
            'We found a phone number, but it needs your confirmation before continuing.';
      } else {
        _infoMessage =
            'Automatic phone number retrieval is not available on this device.';
      }

      _showManualEntry = true;
      notifyListeners();
      return null;
    } catch (_) {
      _isCheckingDevicePhone = false;
      _showManualEntry = true;
      _infoMessage =
          'We could not retrieve a phone number automatically. Enter it manually to continue.';
      notifyListeners();
      return null;
    }
  }

  Future<String?> submitManualNumber(String rawPhone) async {
    if (_isSubmitting) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final String? normalizedPhone = PhoneAuthService.normalizePhoneNumber(
      rawPhone,
    );
    if (normalizedPhone == null) {
      _isSubmitting = false;
      _errorMessage = 'Enter a valid phone number including the country code.';
      notifyListeners();
      return null;
    }

    final PhoneAuthFailure? readinessFailure = await _phoneAuthService
        .ensureReady();
    if (readinessFailure != null) {
      _isSubmitting = false;
      _errorMessage = readinessFailure.message;
      notifyListeners();
      return null;
    }

    await PhoneAuthService.saveLastUsedPhone(normalizedPhone);

    _isSubmitting = false;
    notifyListeners();
    return normalizedPhone;
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}
