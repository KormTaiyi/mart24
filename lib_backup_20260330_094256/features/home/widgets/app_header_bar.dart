import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/shared/widgets/user_avatar.dart';

class AppHeaderBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isAuthenticated;

  const AppHeaderBar({super.key, required this.isAuthenticated});

  @override
  State<AppHeaderBar> createState() => _AppHeaderBarState();

  @override
  Size get preferredSize => Size.fromHeight(isAuthenticated ? 150.0 : 115.0);
}

class _AppHeaderBarState extends State<AppHeaderBar> {
  String selectedLanguage = "Khmer";

  String get currentFlag {
    return selectedLanguage == "Khmer"
        ? "assets/images/khmer_flag.png"
        : "assets/images/uk_flag.png";
  }

  void _switchLanguage() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: LiquidGlassContainer(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Change Language",
                          style: AppTextStyles.title.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            EneftyIcons.close_circle_outline,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildLanguageItem(
                      title: "ខ្មែរ",
                      image: "assets/images/khmer_flag.png",
                      isSelected: selectedLanguage == "Khmer",
                      onTap: () {
                        setState(() {
                          selectedLanguage = "Khmer";
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildLanguageItem(
                      title: "English",
                      image: "assets/images/uk_flag.png",
                      isSelected: selectedLanguage == "English",
                      onTap: () {
                        setState(() {
                          selectedLanguage = "English";
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem({
    required String title,
    required String image,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: isSelected ? 0.26 : 0.18),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSelected ? 0.34 : 0.24),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: AssetImage(image)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_sharp
                    : Icons.radio_button_off,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const String logo = "assets/images/e-mart_v2.png";

    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isAuthenticated) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      logo,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: FavoriteManager.favorites,
                          builder: (context, favorites, _) {
                            return _HeaderActionButton(
                              icon: EneftyIcons.notification_outline,
                              showBadge: favorites.isNotEmpty,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.notification,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _LanguageFlagButton(
                          flagAsset: currentFlag,
                          onTap: _switchLanguage,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const UserAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.sell);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "What on your mind?",
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                EneftyIcons.camera_outline,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(logo, width: 60, height: 60),
                    _LanguageFlagButton(
                      flagAsset: currentFlag,
                      onTap: _switchLanguage,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              "Login",
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: _RegisterButton(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                "Register",
                style: AppTextStyles.subtitle.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageFlagButton extends StatelessWidget {
  final String flagAsset;
  final VoidCallback onTap;

  const _LanguageFlagButton({required this.flagAsset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: CircleAvatar(radius: 14, backgroundImage: AssetImage(flagAsset)),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          if (showBadge)
            Positioned(
              top: -0,
              right: -0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
