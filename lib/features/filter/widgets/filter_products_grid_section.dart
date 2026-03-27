import 'package:flutter/material.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/shared/widgets/product_card.dart';

class FilterProductsGridSection extends StatefulWidget {
  final List<Product> products;

  const FilterProductsGridSection({super.key, required this.products});

  @override
  State<FilterProductsGridSection> createState() =>
      _FilterProductsGridSectionState();
}

class _FilterProductsGridSectionState extends State<FilterProductsGridSection> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  int _responsiveColumns(double width) {
    if (width >= 1100) {
      return 4;
    }
    if (width >= 700) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    final int clampedVisibleCount = _visibleCount > widget.products.length
        ? widget.products.length
        : _visibleCount;
    final List<Product> visibleProducts = widget.products
        .take(clampedVisibleCount)
        .toList();
    final bool hasMore = clampedVisibleCount < widget.products.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const horizontalSpacing = 12.0;
              const verticalSpacing = 12.0;
              final int columns = _responsiveColumns(constraints.maxWidth);
              final double cardWidth =
                  (constraints.maxWidth - horizontalSpacing * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: horizontalSpacing,
                runSpacing: verticalSpacing,
                children: List.generate(visibleProducts.length, (index) {
                  return SizedBox(
                    width: cardWidth,
                    child: ProductCard(product: visibleProducts[index]),
                  );
                }),
              );
            },
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _visibleCount = (_visibleCount + _pageSize).clamp(
                    0,
                    widget.products.length,
                  );
                });
              },
              child: const Text('More products'),
            ),
          ),
      ],
    );
  }
}
