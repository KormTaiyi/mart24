import 'dart:ui';

import 'package:flutter/material.dart';

enum AuthTab { login, register }

class AuthToggle extends StatelessWidget {
  final AuthTab selectedTab;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthToggle({
    super.key,
    required this.selectedTab,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = selectedTab == AuthTab.login;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            // color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleItem(
                  title: 'Login',
                  isSelected: isLogin,
                  onTap: onLoginTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ToggleItem(
                  title: 'Register',
                  isSelected: !isLogin,
                  onTap: onRegisterTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF245E79).withValues(alpha: 0.92)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        border: isSelected
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isSelected ? 1 : 0.92),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
