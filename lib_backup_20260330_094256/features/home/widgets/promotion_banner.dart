import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class PromotionBanner extends StatefulWidget {
  final List<String>? images;

  const PromotionBanner({super.key, this.images});

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner> {
  static const Duration _autoPlayInterval = Duration(seconds: 4);
  static const Duration _scrollDuration = Duration(milliseconds: 550);
  late final PageController _controller;
  Timer? _timer;
  bool _isAutoScrolling = false;

  int get _imageCount => widget.images?.length ?? 0;
  bool get _shouldAutoPlay => _imageCount > 1;

  @override
  void initState() {
    super.initState();
    final int initialPage = _shouldAutoPlay ? _imageCount * 1000 : 0;
    _controller = PageController(initialPage: initialPage);
    _configureAutoPlay();
  }

  @override
  void didUpdateWidget(covariant PromotionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureAutoPlay();
    if (_imageCount <= 1 && _controller.hasClients) {
      _controller.jumpToPage(0);
    }
  }

  void _configureAutoPlay() {
    if (_shouldAutoPlay) {
      _restartAutoPlay();
      return;
    }
    _timer?.cancel();
    _timer = null;
  }

  void _restartAutoPlay() {
    if (!_shouldAutoPlay) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(_autoPlayInterval, (_) => _animateToNextPage());
  }

  Future<void> _animateToNextPage() async {
    if (_isAutoScrolling || !_controller.hasClients || !_shouldAutoPlay) {
      return;
    }
    _isAutoScrolling = true;
    try {
      await _controller.nextPage(
        duration: _scrollDuration,
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // Ignore animation interruptions (for example, if widget is rebuilding).
    } finally {
      _isAutoScrolling = false;
    }
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
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction != ScrollDirection.idle) {
                  _restartAutoPlay();
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                padEnds: false,
                itemCount: _shouldAutoPlay ? null : images.length,
                onPageChanged: (index) {
                  _restartAutoPlay();
                },
                itemBuilder: (context, index) {
                  final String image = images[index % images.length];
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
