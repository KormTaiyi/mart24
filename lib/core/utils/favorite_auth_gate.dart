import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/auth/models/auth_switch_result.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/features/home/models/product.dart';

Future<void> handleFavoriteTap(BuildContext context, Product product) async {
  if (SessionManager.isAuthenticated.value) {
    FavoriteManager.toggle(product);
    return;
  }

  final bool? isAuthenticated = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      return _FavoriteAuthDialog(product: product);
    },
  );

  if (isAuthenticated == true && context.mounted) {
    FavoriteManager.toggle(product);
  }
}

class _FavoriteAuthDialog extends StatelessWidget {
  final Product product;

  const _FavoriteAuthDialog({required this.product});

  Widget _buildAuthScreen(_AuthEntryScreen screen) {
    switch (screen) {
      case _AuthEntryScreen.login:
        return const LoginScreen(
          returnResultOnSuccess: true,
          useSwitchResultForToggle: true,
        );
      case _AuthEntryScreen.register:
        return const RegisterScreen(
          returnResultOnSuccess: true,
          useSwitchResultForToggle: true,
        );
    }
  }

  Route<dynamic> _buildAuthRoute(_AuthEntryScreen screen) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (_, _, _) => _buildAuthScreen(screen),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Future<void> _openAuthScreen(
    BuildContext context, {
    required _AuthEntryScreen initialScreen,
  }) async {
    final navigator = Navigator.of(context);
    _AuthEntryScreen currentScreen = initialScreen;

    while (context.mounted) {
      final dynamic result = await navigator.push<dynamic>(
        _buildAuthRoute(currentScreen),
      );

      if (!context.mounted) {
        return;
      }

      if (result == true) {
        navigator.pop(true);
        return;
      }

      if (result == AuthSwitchResult.toLogin) {
        currentScreen = _AuthEntryScreen.login;
        continue;
      }

      if (result == AuthSwitchResult.toRegister) {
        currentScreen = _AuthEntryScreen.register;
        continue;
      }

      navigator.pop(false);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        EneftyIcons.heart_outline,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Login to save favorites',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(
                        EneftyIcons.close_circle_outline,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Log in or create an account to add ${product.name} to your favorites.',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _GlassActionButton(
                  label: 'Login',
                  isPrimary: true,
                  onTap: () => _openAuthScreen(
                    context,
                    initialScreen: _AuthEntryScreen.login,
                  ),
                ),
                const SizedBox(height: 12),
                _GlassActionButton(
                  label: 'Register',
                  onTap: () => _openAuthScreen(
                    context,
                    initialScreen: _AuthEntryScreen.register,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Maybe later',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _AuthEntryScreen { login, register }

class _GlassActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? Colors.white
        : Colors.white.withValues(alpha: 0.14);

    final foregroundColor = isPrimary ? AppColors.primary : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: backgroundColor,
            border: Border.all(
              color: Colors.white.withValues(alpha: isPrimary ? 0.18 : 0.24),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.subtitle.copyWith(
                color: foregroundColor,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
