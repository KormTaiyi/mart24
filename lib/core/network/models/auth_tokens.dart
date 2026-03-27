class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final String accessToken =
        (json['accessToken'] ??
                json['access_token'] ??
                json['token'] ??
                json['jwt'] ??
                '')
            .toString();

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: (json['refreshToken'] ?? json['refresh_token'] ?? '')
          .toString(),
    );
  }

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  bool get hasRefreshToken => refreshToken.trim().isNotEmpty;

  bool get isValid => hasAccessToken;
}
