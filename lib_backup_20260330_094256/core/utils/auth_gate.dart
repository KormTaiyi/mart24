import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/auth/models/auth_switch_result.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';

// Temporary testing toggle. Set to `false` to re-enable auth gate.
const bool _skipAuthGateForTesting = true;

Future<bool> ensureAuthenticated(
  BuildContext context, {
  required String actionLabel,
}) async {
  if (_skipAuthGateForTesting) {
    return true;
  }

  if (SessionManager.isAuthenticated.value) {
    return true;
  }

  final bool? didAuthenticate = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.26),
    builder: (dialogContext) {
      return _AuthGateDialog(actionLabel: actionLabel);
    },
  );

  return didAuthenticate == true && SessionManager.isAuthenticated.value;
}

class _AuthGateDialog extends StatelessWidget {
  final String actionLabel;

  const _AuthGateDialog({required this.actionLabel});

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
    final NavigatorState navigator = Navigator.of(context);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              color: Colors.white.withValues(alpha: 0.48),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login required',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please login or register to $actionLabel.',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF2A2A2A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openAuthScreen(
                        context,
                        initialScreen: _AuthEntryScreen.register,
                      ),
                      child: const Text('Register'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _openAuthScreen(
                        context,
                        initialScreen: _AuthEntryScreen.login,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ],
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
