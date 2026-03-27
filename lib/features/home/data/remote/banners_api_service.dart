import 'package:flutter/foundation.dart';
import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/home/data/remote/remote_banner.dart';

class BannersApiService {
  BannersApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<RemoteBanner>> fetchActiveBanners({
    String position = 'top',
  }) async {
    final List<List<dynamic>> attempts = <List<dynamic>>[
      <dynamic>[
        ApiEndpoints.banners,
        <String, dynamic>{'position': position},
      ],
      <dynamic>[
        ApiEndpoints.activeBanners,
        <String, dynamic>{'position': position},
      ],
      <dynamic>[ApiEndpoints.activeBanners, null],
      <dynamic>[ApiEndpoints.banners, null],
    ];

    for (final List<dynamic> attempt in attempts) {
      final String path = attempt[0] as String;
      final Map<String, dynamic>? query =
          attempt[1] as Map<String, dynamic>?;

      try {
        final dynamic response = await _client.get<dynamic>(
          path,
          queryParameters: query,
        );
        final List<RemoteBanner> parsed = _parseList(response);
        if (kDebugMode) {
          debugPrint(
            '[BANNER] endpoint=$path query=$query parsed_count=${parsed.length}',
          );
        }
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('[BANNER] endpoint=$path query=$query failed');
        }
        // Try next endpoint shape.
      }
    }

    return const <RemoteBanner>[];
  }

  List<RemoteBanner> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(RemoteBanner.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final List<RemoteBanner> direct = _tryMapList(response);
      if (direct.isNotEmpty) {
        return direct;
      }

      for (final String key in const <String>[
        'data',
        'items',
        'banners',
        'docs',
        'results',
        'rows',
      ]) {
        final dynamic nested = response[key];
        if (nested is List || nested is Map<String, dynamic>) {
          final List<RemoteBanner> parsed = _parseList(nested);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
      }
    }

    return const <RemoteBanner>[];
  }

  List<RemoteBanner> _tryMapList(Map<String, dynamic> map) {
    if (map['id'] == null && map['_id'] == null) {
      return const <RemoteBanner>[];
    }
    return <RemoteBanner>[RemoteBanner.fromJson(map)];
  }
}
