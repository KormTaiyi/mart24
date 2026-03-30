import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/features/auth/services/api/auth_api_service.dart';
import 'package:mart24/features/home/data/remote/remote_banner.dart';
import 'package:mart24/features/home/data/remote/remote_banner_mapper.dart';
import 'package:mart24/features/home/data/remote/remote_category.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';
import 'package:mart24/features/home/data/repositories/banner_repository_impl.dart';
import 'package:mart24/features/home/data/repositories/category_repository_impl.dart';
import 'package:mart24/features/home/data/repositories/product_repository_impl.dart';
import 'package:mart24/features/home/data/remote/remote_product_mapper.dart';
import 'package:mart24/features/home/domain/repositories/banner_repository.dart';
import 'package:mart24/features/home/domain/repositories/category_repository.dart';
import 'package:mart24/features/home/domain/repositories/product_repository.dart';
import 'package:mart24/features/home/models/category.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/home/widgets/all_product_section.dart';
import 'package:mart24/features/home/widgets/app_header_bar.dart';
import 'package:mart24/features/home/widgets/promotion_banner.dart';
import 'package:mart24/shared/widgets/category_section.dart';
import 'package:mart24/features/home/widgets/nearby_products_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepositoryImpl();
  final CategoryRepository _categoryRepository = CategoryRepositoryImpl();
  final BannerRepository _bannerRepository = BannerRepositoryImpl();
  final AuthApiService _authApiService = AuthApiService();

  List<Product>? _remoteProducts;
  List<Map<String, String>>? _remoteCategories;
  List<String>? _remoteBanners;
  double? _viewerLatitude;
  double? _viewerLongitude;

  String? _homeLoadError;
  bool _isLoadingHomeData = false;

  @override
  void initState() {
    super.initState();
    SessionManager.isAuthenticated.addListener(_handleAuthStateChanged);
    _loadHomeData();
  }

  @override
  void dispose() {
    SessionManager.isAuthenticated.removeListener(_handleAuthStateChanged);
    super.dispose();
  }

  void _handleAuthStateChanged() {
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (_isLoadingHomeData) {
      return;
    }

    setState(() {
      _isLoadingHomeData = true;
      _homeLoadError = null;
    });

    bool hasError = false;
    final Future<_ViewerCoordinates> viewerCoordinatesFuture =
        _resolveViewerCoordinates();
    final Future<List<RemoteCategory>> categoriesFuture = _categoryRepository
        .fetchActiveCategories(page: 1, limit: 10);
    final Future<List<RemoteBanner>> bannersFuture = _bannerRepository
        .fetchActiveBanners(position: 'top');

    _ViewerCoordinates viewerCoordinates = const _ViewerCoordinates();
    try {
      viewerCoordinates = await viewerCoordinatesFuture;
    } catch (_) {
      hasError = true;
    }
    _viewerLatitude = viewerCoordinates.latitude;
    _viewerLongitude = viewerCoordinates.longitude;

    final Future<PaginatedResponse<RemoteProduct>> productsFuture =
        _productRepository.fetchProducts(
          page: 1,
          limit: 24,
          latitude: _viewerLatitude,
          longitude: _viewerLongitude,
        );

    List<Product>? nextProducts;
    List<Map<String, String>>? nextCategories;
    List<String>? nextBanners;

    try {
      final PaginatedResponse<RemoteProduct> productsResponse =
          await productsFuture;
      final List<Product> mappedProducts = <Product>[];
      for (final RemoteProduct remote in productsResponse.items) {
        try {
          Product mapped = remote.toUiProduct();
          if (_viewerLatitude != null && _viewerLongitude != null) {
            final double? computedDistanceKm = _distanceBetweenCoordinates(
              fromLatitude: mapped.sellerLatitude,
              fromLongitude: mapped.sellerLongitude,
              toLatitude: _viewerLatitude,
              toLongitude: _viewerLongitude,
            );
            final double? resolvedDistanceKm =
                computedDistanceKm ??
                mapped.distanceKm ??
                _distanceKmFromLabel(mapped.distance);
            mapped = mapped.copyWith(
              clientLatitude: _viewerLatitude,
              clientLongitude: _viewerLongitude,
              distanceKm: resolvedDistanceKm,
              distance: resolvedDistanceKm == null
                  ? mapped.distance
                  : _toDistanceLabel(resolvedDistanceKm),
            );
          }
          mappedProducts.add(mapped);
        } catch (error) {
          hasError = true;
          if (kDebugMode) {
            debugPrint('[HOME] skipping malformed product: $error');
          }
        }
      }
      nextProducts = _deduplicateProducts(mappedProducts);
    } catch (_) {
      hasError = true;
    }

    try {
      final List<RemoteCategory> categoriesResponse = await categoriesFuture;
      nextCategories = categoriesResponse
          .map((remote) => remote.toUiCategoryItem())
          .toList();
    } catch (_) {
      hasError = true;
    }

    try {
      final List<RemoteBanner> mappedBanners = (await bannersFuture).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      nextBanners = mappedBanners
          .map((remote) => remote.toUiBannerImage())
          .where((value) => value.trim().isNotEmpty)
          .toList();
      if (kDebugMode) {
        debugPrint('[BANNER] mapped_ui_count=${nextBanners.length}');
      }
    } catch (_) {
      hasError = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (nextProducts != null) {
        _remoteProducts = nextProducts;
      }
      if (nextCategories != null) {
        _remoteCategories = nextCategories;
      }
      if (nextBanners != null) {
        _remoteBanners = nextBanners;
      }
      _isLoadingHomeData = false;
      _homeLoadError = hasError
          ? 'Some home data failed to load from API.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> products = _remoteProducts ?? const <Product>[];
    final List<Product> nearbyProducts = _buildNearbyProducts(products);
    final List<Map<String, String>> categories =
        _remoteCategories ?? const <Map<String, String>>[];
    final List<String> banners = _remoteBanners ?? const <String>[];
    final bool isHomeEmpty =
        !_isLoadingHomeData &&
        products.isEmpty &&
        categories.isEmpty &&
        banners.isEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: SessionManager.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        return Scaffold(
          appBar: AppHeaderBar(isAuthenticated: isAuthenticated),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                PromotionBanner(images: banners),
                const SizedBox(height: 20),
                CategorySection(
                  title: 'ប្រភេទ',
                  isMore: true,
                  items: categories,
                ),
                if (_isLoadingHomeData)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_homeLoadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _homeLoadError!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                if (isHomeEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Home is empty right now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _homeLoadError ??
                                'No products, categories, or banners were returned yet.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: OutlinedButton(
                              onPressed: _loadHomeData,
                              child: const Text('Retry loading home'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (nearbyProducts.isNotEmpty)
                  NearByProductsSection(
                    title: 'នៅជិតទីតាំងអ្នកក្នុងចម្ងាយ 10គីឡូម៉ែត្រ',
                    isMore: true,
                    products: nearbyProducts,
                  ),
                const SizedBox(height: 20),
                AllProductSection(products: products),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Product> _deduplicateProducts(List<Product> items) {
    final Set<String> seen = <String>{};
    final List<Product> unique = <Product>[];
    for (final Product item in items) {
      final String idKey = item.safeId;
      if (idKey.isNotEmpty) {
        if (seen.contains(idKey)) {
          continue;
        }
        seen.add(idKey);
      }
      unique.add(item);
    }
    return unique;
  }

  List<Product> _buildNearbyProducts(List<Product> products) {
    if (products.isEmpty) {
      return const <Product>[];
    }

    final List<_NearbyEntry> entries = <_NearbyEntry>[];
    int missingDistanceCount = 0;
    for (final Product product in products) {
      final double? distanceKm =
          _distanceBetweenProductAndClient(product) ??
          product.distanceKm ??
          _distanceKmFromLabel(product.distance);
      if (distanceKm == null || distanceKm > 10) {
        if (distanceKm == null) {
          missingDistanceCount++;
        }
        continue;
      }
      entries.add(
        _NearbyEntry(
          product: product.copyWith(
            distanceKm: distanceKm,
            distance: _toDistanceLabel(distanceKm),
          ),
          distanceKm: distanceKm,
        ),
      );
    }

    entries.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (kDebugMode) {
      debugPrint(
        '[NEARBY] viewer=($_viewerLatitude,$_viewerLongitude) total=${products.length} nearby=${entries.length} missing_distance=$missingDistanceCount',
      );
    }
    return entries.map((entry) => entry.product).toList();
  }

  double? _distanceBetweenProductAndClient(Product product) {
    final double? sellerLat = product.sellerLatitude;
    final double? sellerLng = product.sellerLongitude;
    final double? clientLat = _viewerLatitude ?? product.clientLatitude;
    final double? clientLng = _viewerLongitude ?? product.clientLongitude;

    return _distanceBetweenCoordinates(
      fromLatitude: sellerLat,
      fromLongitude: sellerLng,
      toLatitude: clientLat,
      toLongitude: clientLng,
    );
  }

  double? _distanceBetweenCoordinates({
    required double? fromLatitude,
    required double? fromLongitude,
    required double? toLatitude,
    required double? toLongitude,
  }) {
    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return null;
    }

    const double earthRadiusKm = 6371;
    final double dLat = _toRadians(toLatitude - fromLatitude);
    final double dLng = _toRadians(toLongitude - fromLongitude);
    final double fromLatRad = _toRadians(fromLatitude);
    final double toLatRad = _toRadians(toLatitude);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(fromLatRad) *
            math.cos(toLatRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  double? _distanceKmFromLabel(String label) {
    final String normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final double? numeric = _extractLeadingNumber(normalized);
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

  String _toDistanceLabel(double km) {
    if (km < 0) {
      return '';
    }
    if (km >= 100) {
      return '${km.round()}km';
    }
    if (km >= 10) {
      return '${km.toStringAsFixed(0)}km';
    }

    final double rounded = km.roundToDouble();
    if ((km - rounded).abs() < 0.05) {
      return '${km.toStringAsFixed(0)}km';
    }

    return '${km.toStringAsFixed(1)}km';
  }

  double? _extractLeadingNumber(String text) {
    final StringBuffer number = StringBuffer();
    bool hasDot = false;
    bool hasDigit = false;

    for (final int codeUnit in text.codeUnits) {
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

  bool _looksLikeMeters(String normalized) {
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

  Future<_ViewerCoordinates> _resolveViewerCoordinates() async {
    final _ViewerCoordinates fromLocalProfile = _coordinatesFromText(
      ProfileManager.location.value,
    );
    if (!SessionManager.isAuthenticated.value) {
      return fromLocalProfile.isValid
          ? fromLocalProfile
          : const _ViewerCoordinates();
    }

    try {
      final Map<String, dynamic> profile = await _authApiService.getMyProfile();
      final _ViewerCoordinates fromProfile = _viewerCoordinatesFromMap(profile);
      if (fromProfile.isValid) {
        return fromProfile;
      }
    } catch (_) {}

    return fromLocalProfile.isValid
        ? fromLocalProfile
        : const _ViewerCoordinates();
  }

  _ViewerCoordinates _viewerCoordinatesFromMap(Map<String, dynamic> source) {
    final double? lat = _firstDouble(source, const <String>[
      'latitude',
      'lat',
      'current_latitude',
      'currentLatitude',
      'user_latitude',
      'userLatitude',
      'client_latitude',
      'clientLatitude',
      'buyer_latitude',
      'buyerLatitude',
      'customer_latitude',
      'customerLatitude',
    ]);
    final double? lng = _firstDouble(source, const <String>[
      'longitude',
      'lng',
      'lon',
      'long',
      'current_longitude',
      'currentLongitude',
      'user_longitude',
      'userLongitude',
      'client_longitude',
      'clientLongitude',
      'buyer_longitude',
      'buyerLongitude',
      'customer_longitude',
      'customerLongitude',
    ]);

    if (lat != null && lng != null) {
      return _ViewerCoordinates(latitude: lat, longitude: lng);
    }

    for (final String nestedKey in const <String>[
      'location',
      'coordinates',
      'geo',
      'address',
      'current_user',
      'currentUser',
      'user',
      'profile',
      'data',
    ]) {
      final dynamic nested = _valueByCaseInsensitiveKey(source, nestedKey);
      final _ViewerCoordinates nestedCoordinates =
          _viewerCoordinatesFromDynamic(nested);
      if (nestedCoordinates.isValid) {
        return nestedCoordinates;
      }
    }

    return const _ViewerCoordinates();
  }

  _ViewerCoordinates _viewerCoordinatesFromDynamic(dynamic source) {
    if (source is Map<String, dynamic>) {
      return _viewerCoordinatesFromMap(source);
    }

    if (source is List) {
      return _coordinatesFromList(source);
    }

    if (source is String) {
      return _coordinatesFromText(source);
    }

    return const _ViewerCoordinates();
  }

  _ViewerCoordinates _coordinatesFromText(String source) {
    final String value = source.trim();
    if (value.isEmpty) {
      return const _ViewerCoordinates();
    }

    final List<String> parts = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      return const _ViewerCoordinates();
    }

    final double? lat = _extractLeadingNumber(parts[0]);
    final double? lng = _extractLeadingNumber(parts[1]);
    if (lat == null || lng == null) {
      return const _ViewerCoordinates();
    }

    if (!_isValidLatitude(lat) || !_isValidLongitude(lng)) {
      return const _ViewerCoordinates();
    }

    return _ViewerCoordinates(latitude: lat, longitude: lng);
  }

  _ViewerCoordinates _coordinatesFromList(List<dynamic> source) {
    if (source.length < 2) {
      return const _ViewerCoordinates();
    }

    final double? first = _toDouble(source[0]);
    final double? second = _toDouble(source[1]);
    if (first == null || second == null) {
      return const _ViewerCoordinates();
    }

    // GeoJSON commonly stores coordinates as [longitude, latitude].
    if (_isValidLatitude(second) && _isValidLongitude(first)) {
      return _ViewerCoordinates(latitude: second, longitude: first);
    }

    if (_isValidLatitude(first) && _isValidLongitude(second)) {
      return _ViewerCoordinates(latitude: first, longitude: second);
    }

    return const _ViewerCoordinates();
  }

  double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = _valueByCaseInsensitiveKey(source, key);
      final double? parsed = _toDouble(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  dynamic _valueByCaseInsensitiveKey(Map<String, dynamic> source, String key) {
    if (source.containsKey(key)) {
      return source[key];
    }

    final String lowered = key.toLowerCase();
    for (final MapEntry<String, dynamic> entry in source.entries) {
      if (entry.key.toLowerCase() == lowered) {
        return entry.value;
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return _extractLeadingNumber(value);
    }
    return null;
  }

  bool _isValidLatitude(double value) => value >= -90 && value <= 90;
  bool _isValidLongitude(double value) => value >= -180 && value <= 180;
}

class _NearbyEntry {
  const _NearbyEntry({required this.product, required this.distanceKm});

  final Product product;
  final double distanceKm;
}

class _ViewerCoordinates {
  final double? latitude;
  final double? longitude;

  const _ViewerCoordinates({this.latitude, this.longitude});

  bool get isValid => latitude != null && longitude != null;
}
