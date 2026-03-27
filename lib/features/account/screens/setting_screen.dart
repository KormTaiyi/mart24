import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/shared/widgets/user_avatar.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _pauseNotifications = true;
  bool _darkMode = false;

  void _logout() {
    ProfileManager.resetAvatar();
    SessionManager.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SessionManager.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (!isAuthenticated) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F4F4),
            appBar: AppBar(title: const Text('Settings')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Login required',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please login or register to access account settings.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF726B6B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(
                                returnResultOnSuccess: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(
                                returnResultOnSuccess: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F4),
          body: Column(
            children: [
              const _SettingsHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
                  children: [
                    _SettingsSection(
                      children: [
                        _SettingSwitchTile(
                          icon: EneftyIcons.notification_outline,
                          title: 'Pause Notifications',
                          value: _pauseNotifications,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() => _pauseNotifications = value);
                          },
                        ),
                        const _SectionDivider(),
                        const _SettingArrowTile(
                          icon: EneftyIcons.setting_4_outline,
                          title: 'General Setting',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SettingsSection(
                      children: [
                        _SettingSwitchTile(
                          icon: EneftyIcons.moon_outline,
                          title: 'Dark mode',
                          value: _darkMode,
                          activeColor: Colors.black,
                          onChanged: (value) {
                            setState(() => _darkMode = value);
                          },
                        ),
                        const _SectionDivider(),
                        const _SettingArrowTile(
                          icon: EneftyIcons.language_square_outline,
                          title: 'Language',
                        ),
                        const _SectionDivider(),
                        const _SettingArrowTile(
                          icon: EneftyIcons.setting_4_outline,
                          title: 'My Contact',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SettingsSection(
                      children: [
                        _SettingArrowTile(
                          icon: EneftyIcons.message_question_outline,
                          title: 'FAQ',
                        ),
                        _SectionDivider(),
                        _SettingArrowTile(
                          icon: EneftyIcons.info_circle_outline,
                          title: 'Terms of service',
                        ),
                        _SectionDivider(),
                        _SettingArrowTile(
                          icon: EneftyIcons.document_text_outline,
                          title: 'User policy',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: _logout,
                        icon: const Icon(EneftyIcons.logout_outline, size: 20),
                        label: Text(
                          'Log Out',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: ProfileManager.profileListenable,
              builder: (context, _) {
                return Row(
                  children: [
                    const UserAvatar(radius: 35, backgroundColor: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProfileManager.userName.value.trim().isEmpty
                                ? 'No user name yet'
                                : ProfileManager.userName.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ProfileManager.shopName.value.trim().isEmpty
                                ? 'No shop name yet'
                                : ProfileManager.shopName.value,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      EneftyIcons.arrow_right_3_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingArrowTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingArrowTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              EneftyIcons.arrow_right_3_outline,
              color: Colors.black,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor,
            activeThumbColor: Colors.white,
            inactiveTrackColor: Colors.black,
            inactiveThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }
}
