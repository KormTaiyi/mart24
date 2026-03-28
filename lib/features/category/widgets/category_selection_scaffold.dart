import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/core/utils/image_source_resolver.dart';

class CategorySelectionScaffold<T> extends StatelessWidget {
  const CategorySelectionScaffold({
    super.key,
    required this.appBarTitle,
    required this.isLoading,
    required this.errorMessage,
    required this.emptyMessage,
    required this.items,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.onItemTap,
    this.onRetry,
    this.backgroundColor = const Color(0xFFF2F2F2),
    this.appBarTitleFontSize = 20,
    this.itemImageSize = 54,
    this.errorHorizontalPadding = 24,
  });

  final String appBarTitle;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final List<T> items;
  final String Function(T item) itemTitle;
  final String Function(T item) itemImageUrl;
  final ValueChanged<T> onItemTap;
  final VoidCallback? onRetry;
  final Color backgroundColor;
  final double appBarTitleFontSize;
  final double itemImageSize;
  final double errorHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _CategorySelectionErrorState(
        message: errorMessage!,
        onRetry: onRetry,
        horizontalPadding: errorHorizontalPadding,
      );
    }

    if (items.isEmpty) {
      return _CategorySelectionErrorState(
        message: emptyMessage,
        onRetry: onRetry,
        horizontalPadding: errorHorizontalPadding,
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final T item = items[index];
        return _CategorySelectionListItem(
          title: itemTitle(item),
          imageUrl: itemImageUrl(item),
          imageSize: itemImageSize,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

class _CategorySelectionListItem extends StatelessWidget {
  const _CategorySelectionListItem({
    required this.title,
    required this.imageUrl,
    required this.imageSize,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final double imageSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFD8D8D8), width: 1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _CategorySelectionImage(imageUrl: imageUrl, size: imageSize),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF151515),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA8A8A8),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySelectionImage extends StatelessWidget {
  const _CategorySelectionImage({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String source = ImageSourceResolver.resolve(imageUrl);

    Widget child;
    if (ImageSourceResolver.isNetwork(source)) {
      child = Image.network(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (ImageSourceResolver.isAsset(source)) {
      child = Image.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      child = _buildPlaceholder();
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFE9EBF1),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF9AA3BC),
        ),
      ),
    );
  }
}

class _CategorySelectionErrorState extends StatelessWidget {
  const _CategorySelectionErrorState({
    required this.message,
    required this.horizontalPadding,
    this.onRetry,
  });

  final String message;
  final double horizontalPadding;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF606060),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
