import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/notification/widgets/notification_product_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Map<String, int> _quantities = <String, int>{};
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  int _quantityFor(Product product) {
    return _quantities[product.favoriteKey] ?? 1;
  }

  double _unitPrice(Product product) {
    final String normalized = _digitsAndSingleDecimal(product.newPrice);
    return double.tryParse(normalized) ?? 0;
  }

  double _totalPriceFor(List<Product> products) {
    return products.fold<double>(
      0,
      (total, product) => total + (_unitPrice(product) * _quantityFor(product)),
    );
  }

  void _changeQuantity(Product product, int delta) {
    setState(() {
      final int currentValue = _quantityFor(product);
      final int nextValue = currentValue + delta;

      if (nextValue < 1) {
        _quantities.remove(product.favoriteKey);
        FavoriteManager.toggle(product);
        return;
      }

      _quantities[product.favoriteKey] = nextValue.clamp(1, 99);
    });
  }

  String _digitsAndSingleDecimal(String value) {
    final StringBuffer buffer = StringBuffer();
    bool hasDecimalPoint = false;

    for (final int codeUnit in value.codeUnits) {
      final bool isDigit = codeUnit >= 48 && codeUnit <= 57;

      if (isDigit) {
        buffer.writeCharCode(codeUnit);
        continue;
      }

      if (codeUnit == 46 && !hasDecimalPoint) {
        buffer.writeCharCode(codeUnit);
        hasDecimalPoint = true;
      }
    }

    return buffer.toString();
  }

  bool _hasMore(List<Product> products) => _visibleCount < products.length;

  List<Product> _visibleProducts(List<Product> products) {
    final int safeVisibleCount = _visibleCount.clamp(0, products.length);
    return products.take(safeVisibleCount).toList();
  }

  void _loadMore(List<Product> products) {
    if (!_hasMore(products)) {
      return;
    }

    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, products.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SessionManager.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (!isAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Products'),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Login required',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please login or register to save products and use notifications.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(
                                returnResultOnSuccess: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(
                                returnResultOnSuccess: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Products'),
            centerTitle: true,
          ),
          bottomNavigationBar: ValueListenableBuilder<Set<String>>(
            valueListenable: FavoriteManager.favorites,
            builder: (context, _, _) {
              final List<Product> savedProducts =
                  FavoriteManager.favoriteProducts;

              if (savedProducts.isEmpty) {
                return const SizedBox.shrink();
              }

              final int totalQuantity = savedProducts.fold(
                0,
                (total, product) => total + _quantityFor(product),
              );
              final double totalPrice = _totalPriceFor(savedProducts);

              return SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${totalPrice.toStringAsFixed(totalPrice.truncateToDouble() == totalPrice ? 0 : 2)}',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Buy Now ($totalQuantity)',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          body: ValueListenableBuilder<Set<String>>(
            valueListenable: FavoriteManager.favorites,
            builder: (context, _, _) {
              final List<Product> savedProducts =
                  FavoriteManager.favoriteProducts;
              final List<Product> visibleProducts = _visibleProducts(
                savedProducts,
              );
              final bool hasMore = _hasMore(savedProducts);

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  Text(
                    'Saved Products',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjust quantity before buying, or remove a product anytime.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (savedProducts.isEmpty)
                    const _EmptySavedProducts()
                  else
                    ...visibleProducts.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: NotificationProductCard(
                          product: product,
                          quantity: _quantityFor(product),
                          onDecrease: () => _changeQuantity(product, -1),
                          onIncrease: () => _changeQuantity(product, 1),
                        ),
                      ),
                    ),
                  if (hasMore)
                    Center(
                      child: TextButton(
                        onPressed: () => _loadMore(savedProducts),
                        child: const Text('Load more products'),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptySavedProducts extends StatelessWidget {
  const _EmptySavedProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                EneftyIcons.heart_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved products yet',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the favorite icon on any product and it will appear here globally.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
