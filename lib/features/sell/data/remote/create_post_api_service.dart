import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/api_exception.dart';

class PostUploadLimits {
  const PostUploadLimits({this.perImageBytes, this.totalBytes});

  final int? perImageBytes;
  final int? totalBytes;

  bool get hasAny => perImageBytes != null || totalBytes != null;
}

class CreatePostApiService {
  CreatePostApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<PostUploadLimits?> fetchUploadLimits() async {
    final List<({String method, String path, Map<String, dynamic>? query})>
    attempts = <({String method, String path, Map<String, dynamic>? query})>[
      (method: 'OPTIONS', path: ApiEndpoints.createPost, query: null),
      (
        method: 'GET',
        path: ApiEndpoints.publicPosts,
        query: <String, dynamic>{'page': 1, 'limit': 1},
      ),
    ];

    for (final ({String method, String path, Map<String, dynamic>? query})
        attempt
        in attempts) {
      try {
        final Response<dynamic> response = await _client.dio.request<dynamic>(
          attempt.path,
          queryParameters: attempt.query,
          options: Options(method: attempt.method),
        );
        final PostUploadLimits? parsed = _extractUploadLimits(
          responseData: response.data,
          responseHeaders: response.headers.map,
        );
        if (parsed != null && parsed.hasAny) {
          return parsed;
        }
      } catch (_) {
        // Ignore discovery failures and keep defaults.
      }
    }
    return null;
  }

  PostUploadLimits? extractUploadLimitsFromDioError(DioException error) {
    final Response<dynamic>? response = error.response;
    if (response == null) {
      return null;
    }
    return _extractUploadLimits(
      responseData: response.data,
      responseHeaders: response.headers.map,
    );
  }

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String description,
    required double price,
    required int categoryId,
    String status = 'active',
    String? location,
    double? latitude,
    double? longitude,
    String? condition,
    List<String> imagePaths = const <String>[],
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'status': status.trim().isEmpty ? 'active' : status.trim(),
      'category_id': categoryId,
      if (location case final String value when value.trim().isNotEmpty)
        'location': value.trim(),
      if (latitude case final double value) 'latitude': value,
      if (longitude case final double value) 'longitude': value,
      if (condition case final String value when value.trim().isNotEmpty)
        'condition': value.trim(),
    };

    try {
      if (imagePaths.isNotEmpty) {
        final FormData formData = FormData();
        for (final MapEntry<String, dynamic> entry in payload.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }

        for (final String path in imagePaths) {
          final String trimmed = path.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                trimmed,
                filename: _fileName(trimmed),
              ),
            ),
          );
        }

        final Response<dynamic> response = await _client.dio.post<dynamic>(
          ApiEndpoints.createPost,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        return _extractMap(response.data);
      }

      final dynamic response = await _client.post<dynamic>(
        ApiEndpoints.createPost,
        data: payload,
      );
      return _extractMap(response);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  String _fileName(String path) {
    final int slashIndex = path.lastIndexOf('/');
    if (slashIndex < 0 || slashIndex == path.length - 1) {
      return 'image.jpg';
    }
    return path.substring(slashIndex + 1);
  }

  PostUploadLimits? _extractUploadLimits({
    required dynamic responseData,
    required Map<String, List<String>> responseHeaders,
  }) {
    final int? perImageFromBody = _findLimitBytesInPayload(
      responseData,
      keys: _perImageLimitKeys,
    );
    final int? totalFromBody = _findLimitBytesInPayload(
      responseData,
      keys: _totalLimitKeys,
    );
    final int? perImageFromHeaders = _findLimitBytesInHeaders(
      responseHeaders,
      keys: _perImageLimitKeys,
    );
    final int? totalFromHeaders = _findLimitBytesInHeaders(
      responseHeaders,
      keys: _totalLimitKeys,
    );

    int? inferredPerImage = perImageFromBody ?? perImageFromHeaders;
    int? inferredTotal = totalFromBody ?? totalFromHeaders;

    // Fallback: infer from free-form response text when explicit keys are absent.
    if (inferredPerImage == null || inferredTotal == null) {
      final String text = _flattenText(responseData).toLowerCase();
      final int? fallbackBytes = _parseBytes(text);
      if (fallbackBytes != null) {
        if (text.contains('image') ||
            text.contains('file') ||
            text.contains('each')) {
          inferredPerImage ??= fallbackBytes;
        } else if (text.contains('request') ||
            text.contains('payload') ||
            text.contains('total') ||
            text.contains('body') ||
            text.contains('upload')) {
          inferredTotal ??= fallbackBytes;
        }
      }
    }

    if (inferredPerImage == null && inferredTotal == null) {
      return null;
    }

    return PostUploadLimits(
      perImageBytes: inferredPerImage,
      totalBytes: inferredTotal,
    );
  }

  int? _findLimitBytesInHeaders(
    Map<String, List<String>> headers, {
    required Set<String> keys,
  }) {
    for (final MapEntry<String, List<String>> entry in headers.entries) {
      final String key = _normalizeKey(entry.key);
      if (!keys.contains(key)) {
        continue;
      }
      for (final String value in entry.value) {
        final int? parsed = _parseBytes(value, keyHint: key);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return null;
  }

  int? _findLimitBytesInPayload(
    dynamic payload, {
    required Set<String> keys,
    int depth = 0,
  }) {
    if (payload == null || depth > 5) {
      return null;
    }

    final dynamic normalizedPayload = _tryDecodeJsonString(payload);

    if (normalizedPayload is Map) {
      for (final MapEntry<dynamic, dynamic> entry
          in normalizedPayload.entries) {
        final String key = _normalizeKey(entry.key.toString());
        final dynamic value = entry.value;
        if (keys.contains(key)) {
          final int? parsed = _parseBytes(value, keyHint: key);
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
        final int? nested = _findLimitBytesInPayload(
          value,
          keys: keys,
          depth: depth + 1,
        );
        if (nested != null && nested > 0) {
          return nested;
        }
      }
      return null;
    }

    if (normalizedPayload is List) {
      for (final dynamic item in normalizedPayload) {
        final int? nested = _findLimitBytesInPayload(
          item,
          keys: keys,
          depth: depth + 1,
        );
        if (nested != null && nested > 0) {
          return nested;
        }
      }
      return null;
    }

    return null;
  }

  dynamic _tryDecodeJsonString(dynamic value) {
    if (value is! String) {
      return value;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return value;
    }
    if (!((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']')))) {
      return value;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return value;
    }
  }

  String _normalizeKey(String value) {
    final String lower = value.toLowerCase();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final int code = lower.codeUnitAt(i);
      final bool isNumber = code >= 48 && code <= 57;
      final bool isLetter = code >= 97 && code <= 122;
      if (isNumber || isLetter) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  int? _parseBytes(dynamic value, {String? keyHint}) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return _scaleByKeyHint(value.toDouble(), keyHint: keyHint);
    }

    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    final ({double amount, String unit})? sizedValue = _extractSizedValue(text);
    if (sizedValue != null) {
      final double amount = sizedValue.amount;
      final String unit = sizedValue.unit;
      if (amount <= 0) {
        return null;
      }
      if (unit.startsWith('g')) {
        return (amount * 1024 * 1024 * 1024).round();
      }
      if (unit.startsWith('m')) {
        return (amount * 1024 * 1024).round();
      }
      if (unit.startsWith('k')) {
        return (amount * 1024).round();
      }
      return amount.round();
    }

    final double? number = double.tryParse(text);
    if (number == null || number <= 0) {
      return null;
    }
    return _scaleByKeyHint(number, keyHint: keyHint);
  }

  ({double amount, String unit})? _extractSizedValue(String text) {
    final List<String> tokens = _tokenize(text);
    for (int i = 0; i < tokens.length; i++) {
      final String token = tokens[i];
      if (token.isEmpty) {
        continue;
      }

      final ({String numberPart, String unitPart}) split = _splitToken(token);
      if (split.numberPart.isEmpty) {
        continue;
      }

      final double? amount = double.tryParse(split.numberPart);
      if (amount == null || amount <= 0) {
        continue;
      }

      String unit = split.unitPart;
      if (unit.isEmpty && i + 1 < tokens.length) {
        final String next = tokens[i + 1];
        if (_isSupportedUnit(next)) {
          unit = next;
        }
      }

      if (_isSupportedUnit(unit)) {
        return (amount: amount, unit: unit);
      }
    }
    return null;
  }

  List<String> _tokenize(String raw) {
    final String lower = raw.toLowerCase();
    final List<String> tokens = <String>[];
    final StringBuffer current = StringBuffer();

    void flush() {
      if (current.isEmpty) {
        return;
      }
      tokens.add(current.toString());
      current.clear();
    }

    for (int i = 0; i < lower.length; i++) {
      final String char = lower[i];
      final bool isLetter =
          char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122;
      final bool isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      final bool isDot = char == '.';
      if (isLetter || isDigit || isDot) {
        current.write(char);
      } else {
        flush();
      }
    }
    flush();
    return tokens;
  }

  ({String numberPart, String unitPart}) _splitToken(String token) {
    int index = 0;
    while (index < token.length) {
      final int code = token.codeUnitAt(index);
      final bool isDigit = code >= 48 && code <= 57;
      final bool isDot = code == 46;
      if (!isDigit && !isDot) {
        break;
      }
      index++;
    }

    return (
      numberPart: token.substring(0, index),
      unitPart: token.substring(index),
    );
  }

  bool _isSupportedUnit(String unit) {
    return unit == 'gb' ||
        unit == 'gib' ||
        unit == 'mb' ||
        unit == 'mib' ||
        unit == 'kb' ||
        unit == 'kib' ||
        unit == 'byte' ||
        unit == 'bytes' ||
        unit == 'b';
  }

  int? _scaleByKeyHint(double value, {String? keyHint}) {
    if (value <= 0) {
      return null;
    }

    final String hint = (keyHint ?? '').toLowerCase();
    if (hint.contains('gb') || hint.contains('gib')) {
      return (value * 1024 * 1024 * 1024).round();
    }
    if (hint.contains('mb') || hint.contains('mib')) {
      return (value * 1024 * 1024).round();
    }
    if (hint.contains('kb') || hint.contains('kib')) {
      return (value * 1024).round();
    }

    return value.round();
  }

  String _flattenText(dynamic data, {int depth = 0}) {
    if (data == null || depth > 4) {
      return '';
    }
    if (data is String) {
      return data;
    }
    if (data is num || data is bool) {
      return data.toString();
    }
    if (data is Map) {
      return data.values
          .map((dynamic item) => _flattenText(item, depth: depth + 1))
          .where((String value) => value.trim().isNotEmpty)
          .join(' ');
    }
    if (data is List) {
      return data
          .map((dynamic item) => _flattenText(item, depth: depth + 1))
          .where((String value) => value.trim().isNotEmpty)
          .join(' ');
    }
    return data.toString();
  }

  static const Set<String> _perImageLimitKeys = <String>{
    'maximagesize',
    'maximagesizebytes',
    'maximagesizemb',
    'maxfilesize',
    'maxfilesizebytes',
    'maxfilesizemb',
    'imagesizelimit',
    'imagesizelimitbytes',
    'imagesizelimitmb',
    'filesizelimit',
    'filesizelimitbytes',
    'filesizelimitmb',
    'maximageuploadsize',
    'maximageuploadsizebytes',
    'maximageuploadsizemb',
    'imageuploadlimit',
    'imageuploadlimitbytes',
    'imagemaxsize',
  };

  static const Set<String> _totalLimitKeys = <String>{
    'maxtotaluploadsize',
    'maxtotaluploadsizebytes',
    'maxtotaluploadsizemb',
    'maxuploadsize',
    'maxuploadsizebytes',
    'maxuploadsizemb',
    'maxrequestsize',
    'maxrequestsizebytes',
    'maxrequestsizemb',
    'maxbodysize',
    'maxbodysizebytes',
    'maxbodysizemb',
    'requestsizelimit',
    'requestsizelimitbytes',
    'uploadsizelimit',
    'uploadsizelimitbytes',
    'contentlengthlimit',
    'payloadsizelimit',
  };
}
