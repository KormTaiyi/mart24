import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/models/auth_tokens.dart';
import 'package:mart24/core/storage/token_storage.dart';

class AuthApiService {
  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    return loginClient(identifier: identifier, password: password);
  }

  Future<AuthTokens> loginClient({
    required String identifier,
    required String password,
  }) {
    final String normalizedEmail = identifier.trim().toLowerCase();

    return _postAuth(
      path: ApiEndpoints.loginClient,
      data: <String, dynamic>{'email': normalizedEmail, 'password': password},
    );
  }

  Future<AuthTokens> registerClient({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _postAuth(
      path: ApiEndpoints.registerClient,
      data: <String, dynamic>{
        'name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        // Legacy aliases for backend variants.
        'fullName': fullName.trim(),
      },
    );
  }

  Future<AuthTokens> googleLoginClient({
    required String idToken,
    String? accessToken,
  }) {
    return _postAuth(
      path: ApiEndpoints.googleLoginClient,
      data: {
        'idToken': idToken,
        if (accessToken != null && accessToken.trim().isNotEmpty)
          'accessToken': accessToken,
      },
    );
  }

  Future<AuthTokens> googleRegisterClient({
    required String idToken,
    String? accessToken,
  }) {
    return _postAuth(
      path: ApiEndpoints.googleRegisterClient,
      data: {
        'idToken': idToken,
        if (accessToken != null && accessToken.trim().isNotEmpty)
          'accessToken': accessToken,
      },
    );
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    return _postAuth(
      path: ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final dynamic response = await _client.get<dynamic>(ApiEndpoints.profile);
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  Future<AuthTokens> _postAuth({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final dynamic response = await _client.post<dynamic>(path, data: data);
    final AuthTokens tokens = _extractTokens(response);
    if (tokens.hasAccessToken) {
      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.hasRefreshToken ? tokens.refreshToken : null,
      );
    }

    return tokens;
  }

  Future<void> logout() {
    return TokenStorage.clearTokens();
  }

  AuthTokens _extractTokens(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['tokens'] is Map<String, dynamic>) {
        return AuthTokens.fromJson(response['tokens'] as Map<String, dynamic>);
      }
      if (response['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> data =
            response['data'] as Map<String, dynamic>;
        if (data['tokens'] is Map<String, dynamic>) {
          return AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
        }
        return AuthTokens.fromJson(data);
      }
      return AuthTokens.fromJson(response);
    }

    return const AuthTokens(accessToken: '', refreshToken: '');
  }
}
