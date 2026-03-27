import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/storage/token_storage.dart';

class NetworkBootstrap {
  NetworkBootstrap._();

  static Future<void> init({RefreshTokenHandler? refreshTokenHandler}) async {
    ApiClient.instance.configure(
      accessTokenProvider: TokenStorage.getAccessToken,
      refreshTokenHandler: refreshTokenHandler,
    );
  }
}
