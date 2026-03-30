import 'package:flutter/material.dart';
import 'package:mart24/core/network/api_endpoints.dart';

class ImageSourceResolver {
  ImageSourceResolver._();

  static const Set<String> _legacyProductPlaceholders = <String>{
    'assets/images/phone.png',
    'assets/images/e-mart_v2.png',
  };

  static String resolve(String rawSource, {String? baseUrl}) {
    final String value = rawSource.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('assets/')) {
      return value;
    }

    if (_isLikelyLocalFilePath(value)) {
      return value;
    }

    final Uri? uri = Uri.tryParse(value);
    if (uri == null) {
      return '';
    }

    if (uri.hasScheme) {
      return value;
    }

    final String apiBaseUrl = (baseUrl ?? ApiConfig.baseUrl).trim();
    if (apiBaseUrl.isEmpty) {
      return '';
    }

    final Uri? apiUri = Uri.tryParse(apiBaseUrl);
    if (apiUri == null) {
      return '';
    }

    return apiUri.resolve(value).toString();
  }

  static bool isNetwork(String source) {
    final String value = source.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool isAsset(String source) {
    return source.trim().startsWith('assets/');
  }

  static bool isLegacyProductPlaceholder(String source) {
    final String value = source.trim().toLowerCase();
    return value.isNotEmpty && _legacyProductPlaceholders.contains(value);
  }

  static bool shouldIgnoreProductImage(String rawSource, {String? baseUrl}) {
    final String value = resolve(rawSource, baseUrl: baseUrl);
    if (value.isEmpty) {
      return true;
    }
    return isLegacyProductPlaceholder(value);
  }

  static ImageProvider<Object>? toImageProvider(
    String rawSource, {
    String? baseUrl,
  }) {
    final String value = resolve(rawSource, baseUrl: baseUrl);
    if (value.isEmpty) {
      return null;
    }

    if (isNetwork(value)) {
      return NetworkImage(value);
    }

    if (isAsset(value)) {
      return AssetImage(value);
    }

    return null;
  }

  static bool _isLikelyLocalFilePath(String source) {
    if (source.startsWith('/')) {
      return true;
    }

    if (source.length < 3) {
      return false;
    }

    final int driveLetter = source.codeUnitAt(0);
    final int colon = source.codeUnitAt(1);
    final int separator = source.codeUnitAt(2);
    final bool isDriveLetter =
        (driveLetter >= 65 && driveLetter <= 90) ||
        (driveLetter >= 97 && driveLetter <= 122);
    final bool isSeparator = separator == 47 || separator == 92;
    return isDriveLetter && colon == 58 && isSeparator;
  }
}
