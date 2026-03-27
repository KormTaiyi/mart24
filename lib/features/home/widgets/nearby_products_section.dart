import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/home/widgets/home_product_card.dart';

class NearByProductsSection extends StatelessWidget {
  final String? title;
  final bool isMore;
  final List<Product> products;

  const NearByProductsSection({
    super.key,
    this.title,
    required this.isMore,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (isMore)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.filter);
                    },
                    child: const Icon(
                      EneftyIcons.arrow_right_3_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        if (title != null && title!.isNotEmpty) const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth * 0.68;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(products.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == products.length - 1 ? 0 : 15,
                      ),
                      child: SizedBox(
                        width: cardWidth,
                        child: HomeProductCard(product: products[index]),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
