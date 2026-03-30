import 'package:mart24/core/config/app_environment.dart';
import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/mock/mock_api_payloads.dart';
import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';

class ProductsApiService {
  ProductsApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<PaginatedResponse<RemoteProduct>> fetchProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    String status = 'active',
    double? latitude,
    double? longitude,
  }) async {
    if (AppEnvironment.useMockApi) {
      final List<Map<String, dynamic>> filtered = _mockProducts(
        search: search,
        categoryId: categoryId,
        limit: limit,
      );
      return _parsePaginated(
        <String, dynamic>{
          'items': filtered,
          'page': page,
          'limit': limit,
          'total': filtered.length,
        },
        page: page,
        limit: limit,
      );
    }

    final String? trimmedSearch = search?.trim();
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
      'status': status,
      if (trimmedSearch case final String value when value.isNotEmpty)
        'search': value,
      if (categoryId case final int value) 'category_id': value,
      if (latitude case final double value) 'latitude': value,
      if (longitude case final double value) 'longitude': value,
    };

    final dynamic response = await _client.get<dynamic>(
      ApiEndpoints.publicPosts,
      queryParameters: query,
    );

    return _parsePaginated(response, page: page, limit: limit);
  }

  List<Map<String, dynamic>> _mockProducts({
    String? search,
    int? categoryId,
    required int limit,
  }) {
    final String normalizedSearch = (search ?? '').trim().toLowerCase();
    final List<Map<String, dynamic>> base = MockApiPayloads.products
        .map((Map<String, dynamic> item) => Map<String, dynamic>.from(item))
        .where((Map<String, dynamic> item) {
          if (categoryId != null && item['category_id'] != categoryId) {
            return false;
          }

          if (normalizedSearch.isEmpty) {
            return true;
          }

          final String haystack =
              '${item['title'] ?? ''} ${item['name'] ?? ''} ${item['brand'] ?? ''}'
                  .toLowerCase();
          return haystack.contains(normalizedSearch);
        })
        .toList();

    if (limit <= 0 || base.length <= limit) {
      return base;
    }
    return base.sublist(0, limit);
  }

  PaginatedResponse<RemoteProduct> _parsePaginated(
    dynamic response, {
    required int page,
    required int limit,
  }) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return PaginatedResponse<RemoteProduct>.fromJson(
          response['data'] as Map<String, dynamic>,
          RemoteProduct.fromJson,
        );
      }

      return PaginatedResponse<RemoteProduct>.fromJson(
        response,
        RemoteProduct.fromJson,
      );
    }

    if (response is List) {
      final List<RemoteProduct> items = response
          .whereType<Map<String, dynamic>>()
          .map(RemoteProduct.fromJson)
          .toList();
      return PaginatedResponse<RemoteProduct>(
        items: items,
        page: page,
        limit: limit,
        total: items.length,
      );
    }

    return PaginatedResponse<RemoteProduct>(
      items: const <RemoteProduct>[],
      page: page,
      limit: limit,
      total: 0,
    );
  }
}
