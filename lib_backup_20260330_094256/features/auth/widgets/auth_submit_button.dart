import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class AuthSubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const AuthSubmitButton({
    super.key,
    required this.onPressed,
    this.label = 'Submit',
    this.isLoading = false,
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            : Text(
                key: const ValueKey('label'),
                label,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}
