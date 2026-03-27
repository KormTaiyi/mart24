import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/shared/widgets/product_card.dart';

class AllProductSection extends StatefulWidget {
  final List<Product> products;

  const AllProductSection({super.key, required this.products});

  @override
  State<AllProductSection> createState() => _AllProductSectionState();
}

class _AllProductSectionState extends State<AllProductSection> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  int _responsiveColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  bool get _hasMore => _visibleCount < widget.products.length;

  void _loadMore() {
    if (!_hasMore) {
      return;
    }

    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(
        0,
        widget.products.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleProducts = widget.products.take(_visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              "ទំនិញគ្រប់ប្រភេទ",
              style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const horizontalSpacing = 15.0;
              const verticalSpacing = 20.0;
              final columns = _responsiveColumns(constraints.maxWidth);

              final itemWidth =
                  (constraints.maxWidth - horizontalSpacing * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: horizontalSpacing,
                runSpacing: verticalSpacing,
                children: List.generate(
                  visibleProducts.length,
                  (index) => SizedBox(
                    width: itemWidth,
                    child: ProductCard(product: visibleProducts[index]),
                  ),
                ),
              );
            },
          ),
          if (_hasMore)
            Center(
              child: TextButton(
                onPressed: _loadMore,
                child: const Text('More products'),
              ),
            ),
        ],
      ),
    );
  }
}
