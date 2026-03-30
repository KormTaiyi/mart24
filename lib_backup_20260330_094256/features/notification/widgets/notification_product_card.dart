import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/home/screens/product_detail_screen.dart';

class NotificationProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const NotificationProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8E5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 128,
                height: 128,
                color: const Color(0xFFF4F1ED),
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Image.asset(product.image, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 128),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: const Color(0xFF23201D),
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF5F5B56),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            product.newPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(
                              color: const Color(0xFF1D1B18),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _QuantityControl(
                          quantity: quantity,
                          onDecrease: onDecrease,
                          onIncrease: onIncrease,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D2CB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(icon: EneftyIcons.minus_outline, onTap: onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              quantity.toString(),
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF302B26),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(icon: EneftyIcons.add_outline, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF302B26)),
      ),
    );
  }
}
