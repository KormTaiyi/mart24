import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/category/models/post_category.dart';

class CategoryApiService {
  CategoryApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<PostCategory>> fetchCategories({
    int page = 1,
    int limit = 100,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    final List<List<dynamic>> attempts = <List<dynamic>>[
      <dynamic>[ApiEndpoints.categories, query],
      <dynamic>[ApiEndpoints.publicCategories, query],
      <dynamic>[ApiEndpoints.categories, null],
      <dynamic>[ApiEndpoints.publicCategories, null],
    ];

    for (final List<dynamic> attempt in attempts) {
      try {
        final dynamic response = await _client.get<dynamic>(
          attempt[0] as String,
          queryParameters: attempt[1] as Map<String, dynamic>?,
        );
        final List<PostCategory> parsed = _filterActiveCategories(
          _parseCategories(response),
        );
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Fallback to next attempt.
      }
    }

    return const <PostCategory>[];
  }

  Future<List<PostSubCategory>> fetchSubCategories({
    required String categoryId,
  }) async {
    final String normalizedId = categoryId.trim();
    if (normalizedId.isEmpty) {
      return const <PostSubCategory>[];
    }

    try {
      final dynamic response = await _client.get<dynamic>(
        ApiEndpoints.subCategoriesByCategory(normalizedId),
      );
      final List<PostSubCategory> parsed = _filterActiveSubCategories(
        _parseSubCategories(response),
      );
      return parsed;
    } catch (_) {
      return const <PostSubCategory>[];
    }
  }

  List<PostCategory> _parseCategories(dynamic response) {
    final List<dynamic> rawList = _extractList(response);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PostCategory.fromJson)
        .toList();
  }

  List<PostSubCategory> _parseSubCategories(dynamic response) {
    final List<dynamic> rawList = _extractList(response);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PostSubCategory.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        return response['data'] as List<dynamic>;
      }
      if (response['items'] is List) {
        return response['items'] as List<dynamic>;
      }
      if (response['results'] is List) {
        return response['results'] as List<dynamic>;
      }
    }
    return const <dynamic>[];
  }

  List<PostCategory> _filterActiveCategories(List<PostCategory> items) {
    final List<PostCategory> active = items
        .where((PostCategory item) => item.isActive)
        .toList();
    return active.isNotEmpty ? active : items;
  }

  List<PostSubCategory> _filterActiveSubCategories(
    List<PostSubCategory> items,
  ) {
    final List<PostSubCategory> active = items
        .where((PostSubCategory item) => item.isActive)
        .toList();
    return active.isNotEmpty ? active : items;
  }
}
