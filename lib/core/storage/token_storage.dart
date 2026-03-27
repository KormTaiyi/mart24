import 'package:mart24/core/storage/app_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const String _accessTokenKey = 'auth.accessToken.v1';
  static const String _refreshTokenKey = 'auth.refreshToken.v1';

  static Future<String?> getAccessToken() {
    return AppStorage.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() {
    return AppStorage.getString(_refreshTokenKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await AppStorage.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await AppStorage.setString(_refreshTokenKey, refreshToken);
    }
  }

  static Future<void> clearTokens() async {
    await AppStorage.remove(_accessTokenKey);
    await AppStorage.remove(_refreshTokenKey);
  }
}
