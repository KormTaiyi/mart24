class PostCategory {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final List<PostSubCategory> subCategories;

  const PostCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isActive,
    required this.subCategories,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSubCategories =
        (json['sub_categories'] as List<dynamic>?) ??
        (json['subCategories'] as List<dynamic>?) ??
        (json['children'] as List<dynamic>?) ??
        const <dynamic>[];

    return PostCategory(
      id: (json['id'] ?? json['_id'] ?? json['ID'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['icon'] ?? '')
          .toString(),
      isActive: _toBool(json['is_active'] ?? json['isActive']),
      subCategories: rawSubCategories
          .whereType<Map<String, dynamic>>()
          .map(PostSubCategory.fromJson)
          .toList(),
    );
  }
}

class PostSubCategory {
  final String id;
  final String categoryId;
  final String name;
  final String imageUrl;
  final bool isActive;

  const PostSubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.isActive,
  });

  factory PostSubCategory.fromJson(Map<String, dynamic> json) {
    final dynamic categoryRaw =
        json['category_id'] ??
        json['categoryId'] ??
        json['parent_id'] ??
        json['parentId'] ??
        json['category'];
    final String normalizedCategoryId = categoryRaw is Map<String, dynamic>
        ? (categoryRaw['id'] ?? categoryRaw['_id'] ?? categoryRaw['ID'] ?? '')
              .toString()
        : categoryRaw?.toString() ?? '';

    return PostSubCategory(
      id: (json['id'] ?? json['_id'] ?? json['ID'] ?? '').toString(),
      categoryId: normalizedCategoryId,
      name: (json['name'] ?? json['label'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['icon'] ?? '')
          .toString(),
      isActive: _toBool(json['is_active'] ?? json['isActive']),
    );
  }
}

bool _toBool(dynamic raw) {
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    return raw != 0;
  }
  final String normalized = raw?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
