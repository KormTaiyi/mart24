class RemoteCategory {
  final String id;
  final String name;
  final String imageUrl;

  const RemoteCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory RemoteCategory.fromJson(Map<String, dynamic> json) {
    return RemoteCategory(
      id: (json['id'] ?? json['_id'] ?? json['ID'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['icon'] ?? '')
          .toString(),
    );
  }
}
