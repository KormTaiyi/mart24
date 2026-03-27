import 'package:flutter/material.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/category/data/remote/category_api_service.dart';
import 'package:mart24/features/category/models/post_category.dart';
import 'package:mart24/features/category/screen/sub_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryApiService _apiService = CategoryApiService();

  List<PostCategory> _categories = const <PostCategory>[];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PostCategory> categories = await _apiService.fetchCategories(
        page: 1,
        limit: 100,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load categories.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Choose a Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadCategories);
    }

    if (_categories.isEmpty) {
      return _ErrorState(message: 'No categories available.', onRetry: null);
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final PostCategory item = _categories[index];
        return _CategoryListItem(
          title: item.name.trim().isEmpty ? 'Category' : item.name.trim(),
          imageUrl: _normalizeImageUrl(item.imageUrl),
          showBottomBorder: index != _categories.length,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubCategoryScreen(category: item),
              ),
            );
          },
        );
      },
    );
  }

  String _normalizeImageUrl(String rawUrl) {
    final String raw = rawUrl.trim();
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('assets/')) {
      return raw;
    }
    final Uri uri = Uri.parse(raw);
    if (uri.hasScheme) {
      return raw;
    }
    return Uri.parse(ApiConfig.baseUrl).resolve(raw).toString();
  }
}

class _CategoryListItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool showBottomBorder;
  final VoidCallback onTap;

  const _CategoryListItem({
    required this.title,
    required this.imageUrl,
    required this.showBottomBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // color: const Color(0xFFF2F2F2),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: showBottomBorder
                  ? const Color(0xFFD8D8D8)
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _CategoryImage(imageUrl: imageUrl),
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

class _CategoryImage extends StatelessWidget {
  final String imageUrl;

  const _CategoryImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final String source = imageUrl.trim();

    Widget child;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      child = Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(AppAssets.phone, fit: BoxFit.cover),
      );
    } else if (source.startsWith('assets/')) {
      child = Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(AppAssets.phone, fit: BoxFit.cover),
      );
    } else {
      child = Image.asset(AppAssets.phone, fit: BoxFit.cover);
    }

    return SizedBox(
      width: 45,
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
