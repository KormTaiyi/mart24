import 'dart:convert';

class RemoteProduct {
  final String id;
  final String name;
  final String brand;
  final num price;
  final num? oldPrice;
  final String imageUrl;
  final List<String> galleryImages;
  final String description;
  final String postedTime;
  final String date;
  final String capacity;
  final List<String> sizes;
  final String agentName;
  final String agentRole;
  final String agentAvatar;
  final String likes;
  final int views;
  final String distanceLabel;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final double? clientLatitude;
  final double? clientLongitude;
  final double? distanceKm;

  const RemoteProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.oldPrice,
    required this.imageUrl,
    required this.galleryImages,
    required this.description,
    required this.postedTime,
    required this.date,
    required this.capacity,
    required this.sizes,
    required this.agentName,
    required this.agentRole,
    required this.agentAvatar,
    required this.likes,
    required this.views,
    required this.distanceLabel,
    required this.sellerLatitude,
    required this.sellerLongitude,
    required this.clientLatitude,
    required this.clientLongitude,
    required this.distanceKm,
  });

  factory RemoteProduct.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> source = _unwrap(json);
    final dynamic categoryRaw = source['category'];
    final String categoryName = categoryRaw is Map<String, dynamic>
        ? (categoryRaw['name'] ?? '').toString()
        : '';
    final double? sellerLatitude = _firstDouble(source, const <String>[
      'seller_latitude',
      'sellerLatitude',
      'seller_lat',
      'sellerLat',
      'vendor_latitude',
      'vendorLatitude',
      'shop_latitude',
      'shopLatitude',
      'store_latitude',
      'storeLatitude',
      'latitude',
      'lat',
    ]);
    final double? sellerLongitude = _firstDouble(source, const <String>[
      'seller_longitude',
      'sellerLongitude',
      'seller_lng',
      'sellerLng',
      'seller_long',
      'sellerLong',
      'vendor_longitude',
      'vendorLongitude',
      'shop_longitude',
      'shopLongitude',
      'store_longitude',
      'storeLongitude',
      'longitude',
      'lng',
      'lon',
      'long',
    ]);
    final double? clientLatitude = _firstDouble(source, const <String>[
      'client_latitude',
      'clientLatitude',
      'client_lat',
      'clientLat',
      'buyer_latitude',
      'buyerLatitude',
      'customer_latitude',
      'customerLatitude',
      'user_latitude',
      'userLatitude',
      'current_latitude',
      'currentLatitude',
    ]);
    final double? clientLongitude = _firstDouble(source, const <String>[
      'client_longitude',
      'clientLongitude',
      'client_lng',
      'clientLng',
      'client_long',
      'clientLong',
      'buyer_longitude',
      'buyerLongitude',
      'customer_longitude',
      'customerLongitude',
      'user_longitude',
      'userLongitude',
      'current_longitude',
      'currentLongitude',
    ]);

    final String createdAt = _firstNonEmptyString(source, const <String>[
      'createdAt',
      'created_at',
      'postedAt',
      'posted_at',
      'published_at',
      'publishAt',
    ]);

    final String date = _firstNonEmptyString(source, const <String>[
      'date',
      'postedDate',
      'posted_date',
      'publish_date',
    ]);

    final String postedTime = _firstNonEmptyString(source, const <String>[
      'postedTime',
      'posted_time',
      'timeAgo',
      'time_ago',
    ]);
    final String derivedPostedTime = _formatRelativeTime(createdAt);

    final String capacityText = _firstNonEmptyString(source, const <String>[
      'capacity',
      'availability',
      'stock_text',
      'stockLabel',
    ]);

    final num? stockNumber = _numOrNull(
      _firstValueByKeys(source, const <String>[
        'stock',
        'stock_count',
        'stockCount',
        'quantity',
        'qty',
      ]),
    );

    final List<String> sizes = _toStringList(
      _firstValueByKeys(source, const <String>[
        'sizes',
        'sizeOptions',
        'size_options',
        'variants',
      ]),
    );

    final String directAgentName = _firstNonEmptyString(source, const <String>[
      'seller_name',
      'sellerName',
      'vendor_name',
      'vendorName',
      'shop_name',
      'shopName',
      'store_name',
      'storeName',
    ]);

    final String nestedAgentName = _firstNestedString(
      source,
      roleKeys: const <String>[
        'seller',
        'vendor',
        'shop',
        'store',
        'user',
        'owner',
      ],
      fieldKeys: const <String>['name', 'full_name', 'fullName'],
    );

    final String agentRole = _firstNonEmptyString(source, const <String>[
      'seller_role',
      'sellerRole',
      'vendor_role',
      'vendorRole',
      'role',
    ]);

    final String nestedAgentRole = _firstNestedString(
      source,
      roleKeys: const <String>[
        'seller',
        'vendor',
        'shop',
        'store',
        'user',
        'owner',
      ],
      fieldKeys: const <String>['role', 'title', 'position'],
    );

    final String directAgentAvatar =
        _firstNonEmptyString(source, const <String>[
          'seller_avatar',
          'sellerAvatar',
          'vendor_avatar',
          'vendorAvatar',
          'shop_avatar',
          'shopAvatar',
          'store_avatar',
          'storeAvatar',
        ]);

    final String nestedAgentAvatar = _firstNestedString(
      source,
      roleKeys: const <String>[
        'seller',
        'vendor',
        'shop',
        'store',
        'user',
        'owner',
      ],
      fieldKeys: const <String>['avatar', 'avatar_url', 'image', 'photo'],
    );

    final List<String> images = _images(source);
    final String image = _image(source);
    final dynamic distanceRaw = _firstValueByKeys(source, const <String>[
      'distance_km',
      'distanceKm',
      'distance',
      'distance_in_km',
      'distanceInKm',
      'distance_text',
      'distanceText',
      'distance_label',
      'distanceLabel',
    ]);
    final double? parsedDistanceKm = _distanceKmFromRaw(distanceRaw);
    final String parsedDistanceLabel = _distanceLabelFromRaw(distanceRaw);
    final _CoordinatePair? sellerCoordinatePair = _resolveRoleCoordinates(
      source,
      roleKeys: const <String>['seller', 'vendor', 'shop', 'store'],
    );
    final _CoordinatePair? sellerLocationPair = _coordinatePairFromDynamic(
      _firstValueByKeys(source, const <String>[
        'location',
        'coordinates',
        'geo',
        'position',
      ]),
    );
    final _CoordinatePair? clientCoordinatePair = _resolveRoleCoordinates(
      source,
      roleKeys: const <String>[
        'client',
        'buyer',
        'customer',
        'current_user',
        'currentUser',
      ],
    );
    final _CoordinatePair? clientLocationPair = _coordinatePairFromDynamic(
      _firstValueByKeys(source, const <String>[
        'client_location',
        'clientLocation',
        'current_location',
        'currentLocation',
        'viewer_location',
        'viewerLocation',
      ]),
    );

    return RemoteProduct(
      id:
          (source['id'] ??
                  source['_id'] ??
                  source['ID'] ??
                  source['post_id'] ??
                  source['postId'] ??
                  '')
              .toString(),
      name: (source['name'] ?? source['title'] ?? '').toString(),
      brand:
          (source['brand'] ??
                  source['shopName'] ??
                  source['shop_name'] ??
                  source['storeName'] ??
                  categoryName)
              .toString(),
      price: _num(source['price'] ?? source['newPrice']),
      oldPrice: _numOrNull(source['oldPrice']),
      imageUrl: image,
      galleryImages: images,
      description: (source['description'] ?? '').toString(),
      postedTime: postedTime.isNotEmpty
          ? postedTime
          : (derivedPostedTime.isNotEmpty
                ? derivedPostedTime
                : _formatClockTime(createdAt)),
      date: date.isNotEmpty ? date : _formatCalendarDate(createdAt),
      capacity: capacityText.isNotEmpty
          ? capacityText
          : (stockNumber != null ? stockNumber.toString() : ''),
      sizes: sizes,
      agentName: directAgentName.isNotEmpty ? directAgentName : nestedAgentName,
      agentRole: agentRole.isNotEmpty ? agentRole : nestedAgentRole,
      agentAvatar: directAgentAvatar.isNotEmpty
          ? directAgentAvatar
          : nestedAgentAvatar,
      likes: _likesToString(
        _firstValueByKeys(source, const <String>[
          'likes',
          'likeCount',
          'like_count',
          'total_likes',
          'totalLikes',
        ]),
      ),
      views:
          _intOrNull(
            _firstValueByKeys(source, const <String>[
              'views',
              'viewCount',
              'view_count',
              'total_views',
              'totalViews',
            ]),
          ) ??
          0,
      distanceLabel: parsedDistanceLabel,
      sellerLatitude:
          sellerLatitude ??
          sellerCoordinatePair?.latitude ??
          sellerLocationPair?.latitude ??
          _nestedCoordinate(
            source,
            roleKeys: const <String>['seller', 'vendor', 'shop', 'store'],
            coordinateKeys: const <String>['latitude', 'lat'],
          ),
      sellerLongitude:
          sellerLongitude ??
          sellerCoordinatePair?.longitude ??
          sellerLocationPair?.longitude ??
          _nestedCoordinate(
            source,
            roleKeys: const <String>['seller', 'vendor', 'shop', 'store'],
            coordinateKeys: const <String>['longitude', 'lng', 'lon', 'long'],
          ),
      clientLatitude:
          clientLatitude ??
          clientCoordinatePair?.latitude ??
          clientLocationPair?.latitude ??
          _nestedCoordinate(
            source,
            roleKeys: const <String>[
              'client',
              'buyer',
              'customer',
              'current_user',
              'currentUser',
            ],
            coordinateKeys: const <String>['latitude', 'lat'],
          ),
      clientLongitude:
          clientLongitude ??
          clientCoordinatePair?.longitude ??
          clientLocationPair?.longitude ??
          _nestedCoordinate(
            source,
            roleKeys: const <String>[
              'client',
              'buyer',
              'customer',
              'current_user',
              'currentUser',
            ],
            coordinateKeys: const <String>['longitude', 'lng', 'lon', 'long'],
          ),
      distanceKm: parsedDistanceKm,
    );
  }

  static double? _distanceKmFromRaw(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map<String, dynamic>) {
      final double? directKm = _firstDouble(value, const <String>[
        'km',
        'distance_km',
        'distanceKm',
      ]);
      if (directKm != null) {
        return directKm;
      }

      final double? directMeters = _firstDouble(value, const <String>[
        'm',
        'meter',
        'meters',
        'distance_m',
        'distanceM',
      ]);
      if (directMeters != null) {
        return directMeters / 1000;
      }

      final double? numericValue = _doubleOrNull(
        _firstValueByKeys(value, const <String>['value', 'distance', 'amount']),
      );
      if (numericValue == null) {
        return null;
      }

      final String unit = _firstNonEmptyString(value, const <String>[
        'unit',
        'units',
        'distance_unit',
        'distanceUnit',
      ]).toLowerCase();

      final bool isMeters =
          unit.contains('meter') ||
          unit == 'm' ||
          unit == 'metre' ||
          unit == 'metres';
      if (isMeters) {
        return numericValue / 1000;
      }

      return numericValue;
    }

    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      final double? numeric = _doubleOrNull(normalized);
      if (numeric == null) {
        return null;
      }

      final bool hasKm = normalized.contains('km');
      final bool hasMeter = !hasKm && _looksLikeMeters(normalized);
      if (hasMeter) {
        return numeric / 1000;
      }

      return numeric;
    }

    return _doubleOrNull(value);
  }

  static String _distanceLabelFromRaw(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    if (value is Map<String, dynamic>) {
      final String directLabel = _firstNonEmptyString(value, const <String>[
        'label',
        'text',
        'distance_text',
        'distanceText',
      ]);
      if (directLabel.isNotEmpty) {
        return directLabel;
      }

      final double? km = _distanceKmFromRaw(value);
      if (km != null) {
        return '$km km';
      }
      return '';
    }

    if (value is num) {
      return '$value km';
    }

    return value.toString().trim();
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    for (final String key in const <String>[
      'post',
      'product',
      'item',
      'data',
    ]) {
      final dynamic nested = json[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
    }
    return json;
  }

  static String _image(Map<String, dynamic> source) {
    final List<String> images = _images(source);
    return images.isNotEmpty ? images.first : '';
  }

  static List<String> _images(Map<String, dynamic> source) {
    final Set<String> values = <String>{};

    void addRaw(dynamic raw) {
      if (raw == null) {
        return;
      }

      if (raw is String) {
        final String trimmed = raw.trim();
        if (trimmed.isEmpty) {
          return;
        }

        if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
            (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
          final dynamic decoded = _tryDecodeJson(trimmed);
          if (decoded != null) {
            addRaw(decoded);
            return;
          }
        }

        for (final String item in trimmed.split(',')) {
          final String value = _stripWrappingCharacters(item.trim());
          if (value.isNotEmpty) {
            values.add(value);
          }
        }
        return;
      }

      if (raw is List) {
        for (final dynamic item in raw) {
          addRaw(item);
        }
        return;
      }

      if (raw is Map<String, dynamic>) {
        addRaw(
          raw['url'] ??
              raw['secure_url'] ??
              raw['image'] ??
              raw['imageUrl'] ??
              raw['src'] ??
              raw['path'],
        );
      }
    }

    addRaw(source['imageUrl']);
    addRaw(source['image']);
    addRaw(source['images']);
    addRaw(source['thumbnail']);
    addRaw(source['gallery']);
    addRaw(source['galleryImages']);
    addRaw(source['photos']);
    addRaw(source['media']);

    return values.toList();
  }

  static num _num(Object? value) {
    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value) ?? 0;
    }

    return 0;
  }

  static num? _numOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value);
    }

    return null;
  }

  static _CoordinatePair? _resolveRoleCoordinates(
    Map<String, dynamic> source, {
    required List<String> roleKeys,
  }) {
    for (final String roleKey in roleKeys) {
      final dynamic roleData = _valueByCaseInsensitiveKey(source, roleKey);
      final _CoordinatePair? pair = _coordinatePairFromDynamic(roleData);
      if (pair != null) {
        return pair;
      }
    }
    return null;
  }

  static _CoordinatePair? _coordinatePairFromDynamic(
    dynamic value, {
    int depth = 0,
  }) {
    if (value == null || depth > 3) {
      return null;
    }

    if (value is Map<String, dynamic>) {
      final double? lat = _firstDouble(value, const <String>[
        'latitude',
        'lat',
      ]);
      final double? lng = _firstDouble(value, const <String>[
        'longitude',
        'lng',
        'lon',
        'long',
      ]);
      if (lat != null &&
          lng != null &&
          _isValidLatitude(lat) &&
          _isValidLongitude(lng)) {
        return _CoordinatePair(latitude: lat, longitude: lng);
      }

      for (final String key in const <String>[
        'coordinates',
        'coord',
        'position',
        'location',
        'geo',
        'geometry',
      ]) {
        final dynamic nested = _valueByCaseInsensitiveKey(value, key);
        final _CoordinatePair? nestedPair = _coordinatePairFromDynamic(
          nested,
          depth: depth + 1,
        );
        if (nestedPair != null) {
          return nestedPair;
        }
      }
      return null;
    }

    if (value is List) {
      if (value.length < 2) {
        return null;
      }
      final double? first = _doubleOrNull(value[0]);
      final double? second = _doubleOrNull(value[1]);
      if (first == null || second == null) {
        return null;
      }

      if (_isValidLongitude(first) && _isValidLatitude(second)) {
        return _CoordinatePair(latitude: second, longitude: first);
      }
      if (_isValidLatitude(first) && _isValidLongitude(second)) {
        return _CoordinatePair(latitude: first, longitude: second);
      }
      return null;
    }

    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty || !trimmed.contains(',')) {
        return null;
      }
      final List<String> parts = trimmed.split(',');
      if (parts.length < 2) {
        return null;
      }
      final double? first = _doubleOrNull(parts[0]);
      final double? second = _doubleOrNull(parts[1]);
      if (first == null || second == null) {
        return null;
      }

      if (_isValidLongitude(first) && _isValidLatitude(second)) {
        return _CoordinatePair(latitude: second, longitude: first);
      }
      if (_isValidLatitude(first) && _isValidLongitude(second)) {
        return _CoordinatePair(latitude: first, longitude: second);
      }
    }

    return null;
  }

  static int? _intOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static String _likesToString(Object? value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    if (value is num) {
      return value.toString();
    }

    return '';
  }

  static Object? _firstValueByKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = _valueByCaseInsensitiveKey(source, key);
      if (value == null) {
        continue;
      }

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      return value;
    }
    return null;
  }

  static String _firstNonEmptyString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = _valueByCaseInsensitiveKey(source, key);
      if (value == null) {
        continue;
      }

      final String normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  static String _firstNestedString(
    Map<String, dynamic> source, {
    required List<String> roleKeys,
    required List<String> fieldKeys,
  }) {
    for (final String roleKey in roleKeys) {
      final dynamic roleData = _valueByCaseInsensitiveKey(source, roleKey);
      if (roleData is! Map<String, dynamic>) {
        continue;
      }

      final String found = _firstNonEmptyString(roleData, fieldKeys);
      if (found.isNotEmpty) {
        return found;
      }
    }

    return '';
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) {
      return const <String>[];
    }

    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const <String>[];
      }

      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
          (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        final dynamic decoded = _tryDecodeJson(trimmed);
        if (decoded != null && decoded is! String) {
          return _toStringList(decoded);
        }
      }

      return trimmed
          .split(',')
          .map((item) => _stripWrappingCharacters(item.trim()))
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    return const <String>[];
  }

  static String _formatCalendarDate(String raw) {
    final DateTime? date = DateTime.tryParse(raw.trim());
    if (date == null) {
      return '';
    }

    final DateTime local = date.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    return '$day/$month/$year';
  }

  static String _formatClockTime(String raw) {
    final DateTime? date = DateTime.tryParse(raw.trim());
    if (date == null) {
      return '';
    }

    final DateTime local = date.toLocal();
    final int hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute$suffix';
  }

  static String _formatRelativeTime(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return '';
    }

    Duration difference = DateTime.now().difference(parsed.toLocal());
    if (difference.isNegative) {
      difference = Duration.zero;
    }

    if (difference.inMinutes < 1) {
      return '1m';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    }
    return '${(difference.inDays / 365).floor()}y';
  }

  static double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = _valueByCaseInsensitiveKey(source, key);
      final double? parsed = _doubleOrNull(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static double? _nestedCoordinate(
    Map<String, dynamic> source, {
    required List<String> roleKeys,
    required List<String> coordinateKeys,
  }) {
    for (final String roleKey in roleKeys) {
      final dynamic roleData = _valueByCaseInsensitiveKey(source, roleKey);
      if (roleData is Map<String, dynamic>) {
        final double? direct = _firstDouble(roleData, coordinateKeys);
        if (direct != null) {
          return direct;
        }

        final dynamic location =
            _valueByCaseInsensitiveKey(roleData, 'location') ??
            _valueByCaseInsensitiveKey(roleData, 'coordinates') ??
            _valueByCaseInsensitiveKey(roleData, 'geo');

        if (location is Map<String, dynamic>) {
          final double? nested = _firstDouble(location, coordinateKeys);
          if (nested != null) {
            return nested;
          }
        }
      }
    }
    return null;
  }

  static dynamic _valueByCaseInsensitiveKey(
    Map<String, dynamic> source,
    String wantedKey,
  ) {
    if (source.containsKey(wantedKey)) {
      return source[wantedKey];
    }

    final String normalizedWanted = wantedKey.toLowerCase();
    for (final MapEntry<String, dynamic> entry in source.entries) {
      if (entry.key.toLowerCase() == normalizedWanted) {
        return entry.value;
      }
    }

    return null;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final StringBuffer number = StringBuffer();
      bool hasDot = false;
      bool hasDigit = false;

      for (final int codeUnit in trimmed.codeUnits) {
        final bool isDigit = codeUnit >= 48 && codeUnit <= 57;
        final bool isDot = codeUnit == 46;
        final bool isMinus = codeUnit == 45;

        if (isDigit) {
          number.writeCharCode(codeUnit);
          hasDigit = true;
          continue;
        }

        if (isDot && !hasDot) {
          if (number.isEmpty || number.toString() == '-') {
            number.write('0');
          }
          number.write('.');
          hasDot = true;
          continue;
        }

        if (isMinus && number.isEmpty) {
          number.write('-');
          continue;
        }

        if (hasDigit) {
          break;
        }
      }

      if (!hasDigit) {
        return null;
      }

      return double.tryParse(number.toString());
    }

    return null;
  }

  static dynamic _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  static String _stripWrappingCharacters(String source) {
    String value = source.trim();
    const String wrappers = '[]{}()"\''; // Includes single and double quotes.

    while (value.isNotEmpty && wrappers.contains(value[0])) {
      value = value.substring(1).trimLeft();
    }

    while (value.isNotEmpty && wrappers.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1).trimRight();
    }

    return value;
  }

  static bool _looksLikeMeters(String normalized) {
    final String padded = ' ${normalized.trim()} ';
    if (padded.contains(' meter') || padded.contains(' metres')) {
      return true;
    }
    if (padded.contains(' meters') || padded.contains(' metre')) {
      return true;
    }
    if (padded.contains(' m ')) {
      return true;
    }
    return normalized.endsWith('m');
  }

  static bool _isValidLatitude(double value) => value >= -90 && value <= 90;
  static bool _isValidLongitude(double value) => value >= -180 && value <= 180;
}

class _CoordinatePair {
  final double latitude;
  final double longitude;

  const _CoordinatePair({required this.latitude, required this.longitude});
}
