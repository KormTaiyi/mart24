import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/core/utils/favorite_auth_gate.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/home/screens/product_detail_screen.dart';
import 'package:mart24/shared/widgets/favorite_icon.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String sellerName = product.agentName.trim().isEmpty
        ? 'Unknown seller'
        : product.agentName.trim();
    final String titleLabel = product.name.trim().isEmpty
        ? 'Untitled product'
        : product.name.trim();
    final String distance = _formatDistance(
      explicitDistance: product.distance,
      distanceKm: product.distanceKm,
    );
    final String priceLabel = product.newPrice.trim().isEmpty
        ? '\$0'
        : product.newPrice.trim();
    final String oldPriceLabel = product.oldPrice.trim();
    final bool showOldPrice =
        oldPriceLabel.isNotEmpty &&
        oldPriceLabel != priceLabel &&
        oldPriceLabel != '\$0';
    final bool hasDistance = distance.isNotEmpty;

    return Material(
      // color: Colors.green,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: _buildProductImage(product.image),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoriteManager.favorites,
                      builder: (context, favorites, _) {
                        return FavoriteIcon(
                          isFavorite: favorites.contains(product.favoriteKey),
                          onTap: () => handleFavoriteTap(context, product),
                          size: 18,
                          color: AppColors.secondary,
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFD9D9D9),
                          backgroundImage: _avatarImageProvider(
                            product.agentAvatar,
                          ),
                          child:
                              _avatarImageProvider(product.agentAvatar) == null
                              ? Image.asset(
                                  AppAssets.avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_outline,
                                    color: Colors.white70,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (hasDistance) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            EneftyIcons.location_outline,
                            size: 20,
                            color: Color(0xFF707070),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontSize: 18 / 1.15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 18 / 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          priceLabel,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.secondary,
                            fontSize: 34 / 1.9,
                          ),
                        ),
                        if (showOldPrice) ...[
                          const SizedBox(width: 8),
                          Text(
                            oldPriceLabel,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF9A9A9A),
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance({
    required String explicitDistance,
    required double? distanceKm,
  }) {
    final String value = explicitDistance.trim();
    if (value.isNotEmpty) {
      if (value.toLowerCase().contains('km')) {
        return value.replaceAll(' ', '');
      }

      final double? numeric = double.tryParse(value);
      if (numeric != null) {
        return _toDistanceLabel(numeric);
      }

      return value;
    }

    if (distanceKm == null) {
      return '';
    }

    return _toDistanceLabel(distanceKm);
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

  Widget _buildProductImage(String source) {
    final String value = source.trim();
    if (_shouldIgnoreProductImage(value)) {
      return const SizedBox.expand();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      );
    }

    return Image.asset(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }

  bool _shouldIgnoreProductImage(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty || normalized == AppAssets.phone;
  }

  ImageProvider<Object>? _avatarImageProvider(String source) {
    final String value = source.trim();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    if (value.startsWith('assets/')) {
      return AssetImage(value);
    }

    return null;
  }
}
