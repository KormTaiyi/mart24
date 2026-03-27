import 'package:flutter/foundation.dart';
import 'package:mart24/core/storage/app_storage.dart';

class ProfileManager {
  ProfileManager._();

  static const String defaultUserName = '';
  static const String defaultShopName = '';
  static const String defaultPhoneNumber = '';
  static const String defaultEmail = '';
  static const String defaultLocation = '';
  static const String defaultBio = '';
  static const String defaultFacebookUrl = '';
  static const String defaultTelegramUrl = '';
  static const String defaultInstagramUrl = '';
  static const String defaultTiktokUrl = '';

  static final ValueNotifier<String?> avatarPath = ValueNotifier<String?>(null);
  static final ValueNotifier<String> userName = ValueNotifier<String>(
    defaultUserName,
  );
  static final ValueNotifier<String> shopName = ValueNotifier<String>(
    defaultShopName,
  );
  static final ValueNotifier<String> phoneNumber = ValueNotifier<String>(
    defaultPhoneNumber,
  );
  static final ValueNotifier<String> email = ValueNotifier<String>(
    defaultEmail,
  );
  static final ValueNotifier<String> location = ValueNotifier<String>(
    defaultLocation,
  );
  static final ValueNotifier<String> bio = ValueNotifier<String>(defaultBio);
  static final ValueNotifier<String> facebookUrl = ValueNotifier<String>(
    defaultFacebookUrl,
  );
  static final ValueNotifier<String> telegramUrl = ValueNotifier<String>(
    defaultTelegramUrl,
  );
  static final ValueNotifier<String> instagramUrl = ValueNotifier<String>(
    defaultInstagramUrl,
  );
  static final ValueNotifier<String> tiktokUrl = ValueNotifier<String>(
    defaultTiktokUrl,
  );
  static final Listenable profileListenable = Listenable.merge([
    avatarPath,
    userName,
    shopName,
    phoneNumber,
    email,
    location,
    bio,
    facebookUrl,
    telegramUrl,
    instagramUrl,
    tiktokUrl,
  ]);
  static const String _profileStorageKey = 'profile.v1';
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    final Map<String, dynamic>? saved = await AppStorage.getJsonMap(
      _profileStorageKey,
    );
    if (saved != null) {
      avatarPath.value = _stringOrNull(saved['avatarPath']);
      userName.value = _stringOrEmpty(saved['userName'], defaultUserName);
      shopName.value = _stringOrEmpty(saved['shopName'], defaultShopName);
      phoneNumber.value = _stringOrEmpty(
        saved['phoneNumber'],
        defaultPhoneNumber,
      );
      email.value = _stringOrEmpty(saved['email'], defaultEmail);
      location.value = _stringOrEmpty(saved['location'], defaultLocation);
      bio.value = _stringOrEmpty(saved['bio'], defaultBio);
      facebookUrl.value = _stringOrEmpty(
        saved['facebookUrl'],
        defaultFacebookUrl,
      );
      telegramUrl.value = _stringOrEmpty(
        saved['telegramUrl'],
        defaultTelegramUrl,
      );
      instagramUrl.value = _stringOrEmpty(
        saved['instagramUrl'],
        defaultInstagramUrl,
      );
      tiktokUrl.value = _stringOrEmpty(saved['tiktokUrl'], defaultTiktokUrl);
    }

    _isInitialized = true;
  }

  static String _stringOrEmpty(Object? value, String fallback) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static String? _stringOrNull(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static Future<void> _persist() async {
    await AppStorage.setJsonMap(_profileStorageKey, <String, dynamic>{
      'avatarPath': avatarPath.value,
      'userName': userName.value,
      'shopName': shopName.value,
      'phoneNumber': phoneNumber.value,
      'email': email.value,
      'location': location.value,
      'bio': bio.value,
      'facebookUrl': facebookUrl.value,
      'telegramUrl': telegramUrl.value,
      'instagramUrl': instagramUrl.value,
      'tiktokUrl': tiktokUrl.value,
    });
  }

  static void updateAvatar(String path) {
    avatarPath.value = path;
    _persist();
  }

  static void removeAvatar() {
    avatarPath.value = null;
    _persist();
  }

  static void updateProfile({
    required String userNameValue,
    required String shopNameValue,
    required String phoneNumberValue,
    required String emailValue,
    required String locationValue,
    required String bioValue,
    String? facebookUrlValue,
    String? telegramUrlValue,
    String? instagramUrlValue,
    String? tiktokUrlValue,
  }) {
    userName.value = userNameValue.trim();
    shopName.value = shopNameValue.trim();
    phoneNumber.value = phoneNumberValue.trim();
    email.value = emailValue.trim();
    location.value = locationValue.trim();
    bio.value = bioValue.trim();
    facebookUrl.value = facebookUrlValue?.trim() ?? facebookUrl.value;
    telegramUrl.value = telegramUrlValue?.trim() ?? telegramUrl.value;
    instagramUrl.value = instagramUrlValue?.trim() ?? instagramUrl.value;
    tiktokUrl.value = tiktokUrlValue?.trim() ?? tiktokUrl.value;
    _persist();
  }

  static void applyLoginIdentifier(String identifier) {
    final String normalized = identifier.trim();
    if (normalized.isEmpty) {
      return;
    }

    final bool containsAtSymbol = normalized.contains('@');
    final bool looksNumeric = normalized.codeUnits.every(
      (code) => code >= 48 && code <= 57,
    );

    // Only treat a non-email, non-phone identifier as a username.
    if (!containsAtSymbol && !looksNumeric) {
      userName.value = normalized;
      _persist();
    }
  }

  static void resetProfile() {
    userName.value = defaultUserName;
    shopName.value = defaultShopName;
    phoneNumber.value = defaultPhoneNumber;
    email.value = defaultEmail;
    location.value = defaultLocation;
    bio.value = defaultBio;
    facebookUrl.value = defaultFacebookUrl;
    telegramUrl.value = defaultTelegramUrl;
    instagramUrl.value = defaultInstagramUrl;
    tiktokUrl.value = defaultTiktokUrl;
    _persist();
  }

  static void resetAvatar() {
    avatarPath.value = null;
    _persist();
  }
}
