import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DevicePhoneHintService {
  DevicePhoneHintService._();

  static const MethodChannel _channel = MethodChannel(
    'mart24/device_phone_hint',
  );

  static bool get isSupportedOnCurrentPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<String?> getPhoneNumberHint() async {
    if (!isSupportedOnCurrentPlatform) {
      return null;
    }

    try {
      final String? phoneNumber = await _channel.invokeMethod<String>(
        'getPhoneNumberHint',
      );
      final String trimmed = phoneNumber?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
