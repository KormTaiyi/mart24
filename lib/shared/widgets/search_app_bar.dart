import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/routes/app_routes.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String fallbackBackRoute;
  final bool showFilterIcon;

  const SearchAppBar({
    super.key,
    required this.fallbackBackRoute,
    this.showFilterIcon = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: 8,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushReplacementNamed(fallbackBackRoute);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          // fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (showFilterIcon)
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.filter);
                      },
                      icon: const Icon(
                        EneftyIcons.filter_outline,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
