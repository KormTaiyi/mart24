class RemoteBanner {
  final String id;
  final String imageUrl;
  final int sortOrder;

  const RemoteBanner({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory RemoteBanner.fromJson(Map<String, dynamic> json) {
    final dynamic rawImage =
        json['imageUrl'] ??
        json['image_url'] ??
        json['image'] ??
        json['url'] ??
        json['bannerUrl'] ??
        json['banner_url'];

    final String imageUrl = switch (rawImage) {
      final String value => value,
      final Map<String, dynamic> value =>
        (value['url'] ?? value['secure_url'] ?? '').toString(),
      _ => '',
    };

    return RemoteBanner(
      id: (json['id'] ?? json['_id'] ?? json['ID'] ?? '').toString(),
      imageUrl: imageUrl,
      sortOrder: _readInt(json['sort_order'] ?? json['sortOrder']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
