import 'package:flutter/material.dart';
import 'package:mart24/features/category/data/remote/category_api_service.dart';
import 'package:mart24/features/category/models/post_category.dart';
import 'package:mart24/features/category/screen/sub_category_screen.dart';
import 'package:mart24/features/category/widgets/category_selection_scaffold.dart';

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
    return CategorySelectionScaffold<PostCategory>(
      appBarTitle: 'Choose a Category',
      appBarTitleFontSize: 22,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      emptyMessage: 'No categories available.',
      items: _categories,
      itemTitle: (PostCategory item) =>
          item.name.trim().isEmpty ? 'Category' : item.name.trim(),
      itemImageUrl: (PostCategory item) => item.imageUrl,
      onItemTap: _openSubCategory,
      onRetry: _loadCategories,
      itemImageSize: 45,
      errorHorizontalPadding: 4,
    );
  }

  void _openSubCategory(PostCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubCategoryScreen(category: category)),
    );
  }
}
