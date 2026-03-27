import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),

    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.headline,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.subtitle,
      bodyLarge: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
    ),
  );
}
