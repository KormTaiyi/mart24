import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class AuthSocialButtons extends StatelessWidget {
  final VoidCallback onAppleTap;
  final VoidCallback onGoogleTap;
  final VoidCallback onPhoneTap;
  final bool showTerms;
  final bool isLoading;
  final bool? showAppleButton;

  const AuthSocialButtons({
    super.key,
    required this.onAppleTap,
    required this.onGoogleTap,
    required this.onPhoneTap,
    this.showTerms = false,
    this.isLoading = false,
    this.showAppleButton,
  });

  @override
  Widget build(BuildContext context) {
    final bool canShowApple =
        showAppleButton ??
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.35),
                  endIndent: 10,
                ),
              ),
              Text(
                "Or Continue With",
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.35),
                  indent: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.65 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canShowApple) ...[
                  _SocialCircleButton(
                    onTap: onAppleTap,
                    child: Image.asset(
                      "assets/images/apple.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                _SocialCircleButton(
                  onTap: onGoogleTap,
                  child: Image.asset(
                    "assets/images/google.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                _SocialCircleButton(
                  onTap: onPhoneTap,
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Color(0xFF2E3A59),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showTerms) ...[
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xFFBDD0D9),
                fontSize: 13,
                height: 1.35,
              ),
              children: [
                const TextSpan(
                  text:
                      'By clicking "Continue", I have read and agree with the ',
                ),
                TextSpan(
                  text: 'Term Sheet, Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SocialCircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 55,
          height: 55,
          child: Center(child: SizedBox(width: 35, height: 35, child: child)),
        ),
      ),
    );
  }
}
