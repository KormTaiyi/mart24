import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/utils/auth_gate.dart';
import 'package:mart24/features/account/screens/account_screen.dart';
import 'package:mart24/features/category/screen/category_screen.dart';
import 'package:mart24/features/chat/screens/list_chat_screen.dart';
import 'package:mart24/features/home/screens/home_screen.dart';
import 'package:mart24/features/search/screens/search_screen.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/shared/widgets/user_avatar.dart';

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

class AppBottomBar extends StatefulWidget {
  final int initialIndex;

  const AppBottomBar({super.key, this.initialIndex = 0});

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  static const List<NavItem> _navItems = [
    NavItem(icon: EneftyIcons.home_2_bold, label: 'Home'),
    NavItem(icon: EneftyIcons.search_status_2_outline, label: 'Search'),
    NavItem(icon: EneftyIcons.add_square_outline, label: 'Post'),
    NavItem(icon: EneftyIcons.message_bold, label: 'Chat'),
    NavItem(icon: EneftyIcons.profile_circle_outline, label: 'Account'),
  ];

  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const HomeScreen(),
      const SearchScreen(),
      const CategoryScreen(),
      const ListChatScreen(),
      const AccountScreen(),
    ];
  }

  Future<void> _handleBottomNavTap(int index) async {
    if (index == 2 || index == 3) {
      final bool isAllowed = await ensureAuthenticated(
        context,
        actionLabel: index == 2 ? 'post products' : 'open chat',
      );

      if (!mounted || !isAllowed) {
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: isAndroid
          ? SafeArea(
              top: false,
              left: false,
              right: false,
              child: _CustomBottomNavBar(
                currentIndex: _currentIndex,
                items: _navItems,
                onTap: _handleBottomNavTap,
              ),
            )
          : _CustomBottomNavBar(
              currentIndex: _currentIndex,
              items: _navItems,
              onTap: _handleBottomNavTap,
            ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mainItems = items.take(4).toList();

    return Container(
      color: const Color(0xFFF1F1F1),
      padding: EdgeInsets.fromLTRB(
        10,
        5,
        10,
        defaultTargetPlatform == TargetPlatform.iOS ? 14 : 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(mainItems.length, (index) {
                  final item = mainItems[index];
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: _NavButton(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _ProfileNavButton(
            isSelected: currentIndex == items.length - 1,
            onTap: () => onTap(items.length - 1),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected
        ? AppColors.primary
        : const Color(0xFF121212);

    return InkWell(
      onTap: onTap,
      // borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDEDED) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: foreground),
            // const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileNavButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: UserAvatar(
            radius: 29,
            backgroundColor: const Color(0xFFEDEDED),
          ),
        ),
      ),
    );
  }
}
