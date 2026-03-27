import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';

class FavoriteIcon extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const FavoriteIcon({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 24,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? EneftyIcons.heart_bold : EneftyIcons.heart_outline,
          size: size,
          color: color ?? (isFavorite ? Colors.red : Colors.grey),
        ),
      ),
    );
  }
}
