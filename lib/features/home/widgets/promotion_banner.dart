import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class PromotionBanner extends StatefulWidget {
  final List<String>? images;

  const PromotionBanner({super.key, this.images});

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final List<String> images = widget.images ?? const <String>[];
      if (!_controller.hasClients || images.length <= 1) return;

      final int nextPage = (_currentPage + 1) % images.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _currentPage = nextPage;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.images ?? const <String>[];
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ដំណឹង & ប្រមូលសិន",
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Container(
            height: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.hardEdge,
            child: images.isEmpty
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _controller,
                    padEnds: false,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      _currentPage = index;
                    },
                    itemBuilder: (context, index) {
                      final image = images[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildImage(image),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String image) {
    final String value = image.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFEDEDED)),
      );
    }

    return Image.asset(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFEDEDED)),
    );
  }
}
