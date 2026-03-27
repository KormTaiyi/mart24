import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/storage/app_storage.dart';
import 'package:mart24/core/storage/token_storage.dart';

class SessionManager {
  SessionManager._();

  static const String _authStorageKey = 'session.isAuthenticated.v1';
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await ProfileManager.init();
    final bool savedSession = await AppStorage.getBool(_authStorageKey) ?? false;
    final String? accessToken = await TokenStorage.getAccessToken();
    final bool hasToken = accessToken != null && accessToken.trim().isNotEmpty;
    isAuthenticated.value = savedSession || hasToken;
    AppStorage.setBool(_authStorageKey, isAuthenticated.value);
    _isInitialized = true;
  }

  static void login({String? identifier}) {
    isAuthenticated.value = true;
    AppStorage.setBool(_authStorageKey, true);

    if (ProfileManager.userName.value.trim().isEmpty &&
        ProfileManager.shopName.value.trim().isEmpty &&
        ProfileManager.phoneNumber.value.trim().isEmpty &&
        ProfileManager.email.value.trim().isEmpty &&
        ProfileManager.location.value.trim().isEmpty &&
        ProfileManager.bio.value.trim().isEmpty) {
      ProfileManager.resetProfile();
    }

    if (identifier != null) {
      ProfileManager.applyLoginIdentifier(identifier);
    }
  }

  static void logout() {
    isAuthenticated.value = false;
    AppStorage.setBool(_authStorageKey, false);
    ProfileManager.resetProfile();
    ProfileManager.resetAvatar();
    unawaited(_signOutProviders());
  }

  static Future<void> _signOutProviders() async {
    await TokenStorage.clearTokens();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }
}
