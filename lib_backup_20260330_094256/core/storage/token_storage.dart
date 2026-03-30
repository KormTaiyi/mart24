import 'package:mart24/core/storage/app_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const String _accessTokenKey = 'auth.accessToken.v1';
  static const String _refreshTokenKey = 'auth.refreshToken.v1';
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static bool _didLoadAccessToken = false;
  static bool _didLoadRefreshToken = false;
  static Future<String?>? _accessTokenInFlight;
  static Future<String?>? _refreshTokenInFlight;

  static Future<String?> getAccessToken() {
    if (_didLoadAccessToken) {
      return Future<String?>.value(_cachedAccessToken);
    }

    final Future<String?>? activeRequest = _accessTokenInFlight;
    if (activeRequest != null) {
      return activeRequest;
    }

    final Future<String?> readFuture = AppStorage.getString(_accessTokenKey)
        .then((String? token) {
          _cachedAccessToken = token;
          _didLoadAccessToken = true;
          return token;
        })
        .whenComplete(() {
          _accessTokenInFlight = null;
        });
    _accessTokenInFlight = readFuture;
    return readFuture;
  }

  static Future<String?> getRefreshToken() {
    if (_didLoadRefreshToken) {
      return Future<String?>.value(_cachedRefreshToken);
    }

    final Future<String?>? activeRequest = _refreshTokenInFlight;
    if (activeRequest != null) {
      return activeRequest;
    }

    final Future<String?> readFuture = AppStorage.getString(_refreshTokenKey)
        .then((String? token) {
          _cachedRefreshToken = token;
          _didLoadRefreshToken = true;
          return token;
        })
        .whenComplete(() {
          _refreshTokenInFlight = null;
        });
    _refreshTokenInFlight = readFuture;
    return readFuture;
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    _didLoadAccessToken = true;
    await AppStorage.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      _cachedRefreshToken = refreshToken;
      _didLoadRefreshToken = true;
      await AppStorage.setString(_refreshTokenKey, refreshToken);
    }
  }

  static Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _didLoadAccessToken = true;
    _didLoadRefreshToken = true;
    _accessTokenInFlight = null;
    _refreshTokenInFlight = null;
    await AppStorage.remove(_accessTokenKey);
    await AppStorage.remove(_refreshTokenKey);
  }
}
