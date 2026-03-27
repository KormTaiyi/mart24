class Product {
  final String id;
  final String image;
  final String name;
  final String brand;
  final String distance;
  final String oldPrice;
  final String newPrice;
  final List<String> galleryImages;
  final String postedTime;
  final String date;
  final String capacity;
  final String description;
  final List<String> sizes;
  final String agentName;
  final String agentRole;
  final String agentAvatar;
  final String likes;
  final int views;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final double? clientLatitude;
  final double? clientLongitude;
  final double? distanceKm;
  final bool isFavorite;

  const Product({
    this.id = '',
    required this.image,
    required this.name,
    required this.brand,
    required this.distance,
    required this.oldPrice,
    required this.newPrice,
    required this.galleryImages,
    required this.postedTime,
    required this.date,
    required this.capacity,
    required this.description,
    required this.sizes,
    required this.agentName,
    required this.agentRole,
    required this.agentAvatar,
    required this.likes,
    required this.views,
    this.sellerLatitude,
    this.sellerLongitude,
    this.clientLatitude,
    this.clientLongitude,
    this.distanceKm,
    this.isFavorite = false,
  });

  Product copyWith({
    String? id,
    bool? isFavorite,
    String? name,
    String? distance,
    String? newPrice,
    String? description,
    double? sellerLatitude,
    double? sellerLongitude,
    double? clientLatitude,
    double? clientLongitude,
    double? distanceKm,
  }) {
    return Product(
      id: id ?? this.id,
      image: image,
      name: name ?? this.name,
      brand: brand,
      distance: distance ?? this.distance,
      oldPrice: oldPrice,
      newPrice: newPrice ?? this.newPrice,
      galleryImages: galleryImages,
      postedTime: postedTime,
      date: date,
      capacity: capacity,
      description: description ?? this.description,
      sizes: sizes,
      agentName: agentName,
      agentRole: agentRole,
      agentAvatar: agentAvatar,
      likes: likes,
      views: views,
      sellerLatitude: sellerLatitude ?? this.sellerLatitude,
      sellerLongitude: sellerLongitude ?? this.sellerLongitude,
      clientLatitude: clientLatitude ?? this.clientLatitude,
      clientLongitude: clientLongitude ?? this.clientLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Product copyWithDetails({
    String? name,
    String? newPrice,
    String? description,
  }) {
    return copyWith(name: name, newPrice: newPrice, description: description);
  }

  String get favoriteKey => stableKey;
  String get safeId => id.trim();

  String get stableKey => safeId.isNotEmpty ? safeId : image;
}

extension ProductGallery on Product {
  List<String> get relatedGalleryImages {
    final List<String> explicitGallery = galleryImages
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    if (explicitGallery.isNotEmpty) {
      return explicitGallery;
    }

    final String normalizedImage = image.trim();
    if (normalizedImage.isNotEmpty) {
      return <String>[normalizedImage];
    }

    return const <String>[];
  }
}
