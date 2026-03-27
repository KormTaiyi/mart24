import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class AuthSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AuthSubmitButton({
    super.key,
    required this.onPressed,
    this.label = 'Submit',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.primary,
          fontSize: 18,
        ),
      ),
    );
  }
}
