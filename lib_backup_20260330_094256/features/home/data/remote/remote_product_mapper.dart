import 'dart:math' as math;

import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';
import 'package:mart24/features/home/models/product.dart';

extension RemoteProductMapper on RemoteProduct {
  Product toUiProduct() {
    final String image = _normalizeImage(imageUrl);
    final List<String> gallery = _normalizeGallery(galleryImages, image);
    final num currentPrice = price <= 0 ? 0 : price;
    final num previousPrice = oldPrice != null && oldPrice! > 0
        ? oldPrice!
        : currentPrice;
    final double? kmFromCoordinates = _haversineKm(
      sellerLatitude,
      sellerLongitude,
      clientLatitude,
      clientLongitude,
    );
    final double? resolvedDistanceKm = kmFromCoordinates ?? distanceKm;
    final String resolvedDistance = _normalizeDistanceLabel(
      numericDistanceKm: resolvedDistanceKm,
      rawDistanceLabel: distanceLabel,
    );

    return Product(
      id: id,
      image: image,
      name: name.trim(),
      brand: brand.trim(),
      distance: resolvedDistance,
      oldPrice: _asMoney(previousPrice),
      newPrice: _asMoney(currentPrice),
      galleryImages: gallery,
      postedTime: postedTime.trim(),
      date: date.trim(),
      capacity: capacity.trim(),
      description: description.trim(),
      sizes: _normalizeSizes(sizes),
      agentName: agentName.trim(),
      agentRole: agentRole.trim(),
      agentAvatar: _normalizeAgentAvatar(agentAvatar),
      likes: likes.trim(),
      views: views,
      sellerLatitude: sellerLatitude,
      sellerLongitude: sellerLongitude,
      clientLatitude: clientLatitude,
      clientLongitude: clientLongitude,
      distanceKm: resolvedDistanceKm,
    );
  }
}

String _normalizeDistanceLabel({
  required double? numericDistanceKm,
  required String rawDistanceLabel,
}) {
  if (numericDistanceKm != null) {
    return '${numericDistanceKm.toStringAsFixed(1)}km';
  }

  final String value = rawDistanceLabel.trim();
  if (value.isEmpty) {
    return '';
  }

  if (value.toLowerCase().contains('km')) {
    return value;
  }

  final double? numeric = double.tryParse(value);
  if (numeric != null) {
    return '${numeric.toStringAsFixed(1)}km';
  }

  return value;
}

String _normalizeImage(String source) {
  final String normalized = source.trim();
  if (normalized.isEmpty) {
    return '';
  }

  final String firstImage = normalized.contains(',')
      ? normalized.split(',').first.trim()
      : normalized;

  final String resolved = _resolveImageUrl(firstImage);
  if (_isSupportedImage(resolved) && !_isPlaceholderProductImage(resolved)) {
    return resolved;
  }

  return '';
}

List<String> _normalizeGallery(List<String> source, String primaryImage) {
  final Set<String> values = <String>{};

  for (final String item in source) {
    final String value = _resolveImageUrl(item.trim());
    if (value.isEmpty) {
      continue;
    }
    if (_isSupportedImage(value) && !_isPlaceholderProductImage(value)) {
      values.add(value);
    }
  }

  final String normalizedPrimary = primaryImage.trim();
  if (normalizedPrimary.isNotEmpty &&
      !_isPlaceholderProductImage(normalizedPrimary)) {
    values.add(normalizedPrimary);
  }

  return values.toList();
}

List<String> _normalizeSizes(List<String> source) {
  return source
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}

String _normalizeAgentAvatar(String source) {
  final String value = _resolveImageUrl(source.trim());
  if (_isSupportedImage(value)) {
    return value;
  }
  return '';
}

String _resolveImageUrl(String source) {
  final String value = source.trim();
  if (value.isEmpty) {
    return '';
  }

  if (value.startsWith('assets/')) {
    return value;
  }

  final Uri? uri = Uri.tryParse(value);
  if (uri == null) {
    return '';
  }
  if (uri.hasScheme) {
    return value;
  }

  return Uri.parse(ApiConfig.baseUrl).resolve(value).toString();
}

bool _isSupportedImage(String source) {
  if (source.isEmpty) {
    return false;
  }

  return source.startsWith('assets/') ||
      source.startsWith('http://') ||
      source.startsWith('https://');
}

bool _isPlaceholderProductImage(String source) {
  final String value = source.trim().toLowerCase();
  return value == 'assets/images/phone.png' ||
      value == 'assets/images/e-mart_v2.png';
}

String _asMoney(num value) {
  final String normalized = value.toStringAsFixed(2);
  if (normalized.endsWith('.00')) {
    return '\$${normalized.substring(0, normalized.length - 3)}';
  }
  return '\$$normalized';
}

double? _haversineKm(
  double? fromLatitude,
  double? fromLongitude,
  double? toLatitude,
  double? toLongitude,
) {
  if (fromLatitude == null ||
      fromLongitude == null ||
      toLatitude == null ||
      toLongitude == null) {
    return null;
  }

  const double earthRadiusKm = 6371;
  final double dLat = _toRadians(toLatitude - fromLatitude);
  final double dLon = _toRadians(toLongitude - fromLongitude);
  final double lat1 = _toRadians(fromLatitude);
  final double lat2 = _toRadians(toLatitude);
  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * (math.pi / 180);
