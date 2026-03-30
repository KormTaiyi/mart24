import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/shared/widgets/product_card.dart';

class PopularSection extends StatelessWidget {
  final String? title;
  final List<Product> products;

  const PopularSection({
    super.key,
    this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && title!.isNotEmpty)
          Text(
            title!,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
          ),
        if (title != null && title!.isNotEmpty) const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (products.isEmpty) {
              return Text(
                'No popular products yet.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              );
            }

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
                      child: ProductCard(product: products[index]),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
