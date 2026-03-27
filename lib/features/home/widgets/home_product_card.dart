import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_shadow.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/core/utils/favorite_auth_gate.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/home/screens/product_detail_screen.dart';
import 'package:mart24/shared/widgets/favorite_icon.dart';

class HomeProductCard extends StatelessWidget {
  final Product product;

  const HomeProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String postedTime = product.postedTime.trim();
    final String distance = product.distance.trim();
    final bool hasPostedTime = postedTime.isNotEmpty;
    final bool hasDistance = distance.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: _buildProductImage(product.image),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 5,
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: FavoriteManager.favorites,
                    builder: (context, favorites, _) {
                      return FavoriteIcon(
                        isFavorite: favorites.contains(product.favoriteKey),
                        onTap: () => handleFavoriteTap(context, product),
                      );
                    },
                  ),
                ),
              ],
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hasPostedTime)
                        Text(
                          postedTime,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      if (hasPostedTime && hasDistance) ...[
                        const SizedBox(width: 5),
                        const Text(
                          '|',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (hasDistance)
                        const Icon(
                          EneftyIcons.location_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      if (hasDistance)
                        Text(
                          distance,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        product.newPrice,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String source) {
    final String value = source.trim();
    if (_shouldIgnoreProductImage(value)) {
      return const SizedBox.expand();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      );
    }

    return Image.asset(
      value,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }

  bool _shouldIgnoreProductImage(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty || normalized == AppAssets.phone;
  }
}
