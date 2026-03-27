import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/home/data/remote/remote_category.dart';

class CategoriesApiService {
  CategoriesApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<RemoteCategory>> fetchActiveCategories({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final List<List<dynamic>> attempts = <List<dynamic>>[
      <dynamic>[ApiEndpoints.activeCategories, query],
      <dynamic>[ApiEndpoints.publicCategories, query],
      <dynamic>[ApiEndpoints.activeCategories, null],
      <dynamic>[ApiEndpoints.publicCategories, null],
    ];

    for (final List<dynamic> attempt in attempts) {
      try {
        final dynamic response = await _client.get<dynamic>(
          attempt[0] as String,
          queryParameters: attempt[1] as Map<String, dynamic>?,
        );
        final List<RemoteCategory> parsed = _parseList(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Try next endpoint shape.
      }
    }

    return const <RemoteCategory>[];
  }

  List<RemoteCategory> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(RemoteCategory.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        return (response['data'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(RemoteCategory.fromJson)
            .toList();
      }

      if (response['items'] is List) {
        return (response['items'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(RemoteCategory.fromJson)
            .toList();
      }
    }

    return const <RemoteCategory>[];
  }
}
