class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;

  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  bool get hasMore => page * limit < total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromJson,
  ) {
    final List<dynamic> rawItems;

    if (json['items'] is List) {
      rawItems = json['items'] as List<dynamic>;
    } else if (json['data'] is List) {
      rawItems = json['data'] as List<dynamic>;
    } else {
      rawItems = const <dynamic>[];
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();

    final int page = (json['page'] as num?)?.toInt() ?? 1;
    final int limit = (json['limit'] as num?)?.toInt() ?? items.length;
    final int total =
        (json['total'] as num?)?.toInt() ??
        (json['count'] as num?)?.toInt() ??
        items.length;

    return PaginatedResponse<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
    );
  }
}
