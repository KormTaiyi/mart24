import 'package:flutter/material.dart';
import 'package:mart24/features/category/data/remote/category_api_service.dart';
import 'package:mart24/features/category/models/post_category.dart';
import 'package:mart24/features/category/screen/create_post_form.dart';
import 'package:mart24/features/category/widgets/category_selection_scaffold.dart';

class SubCategoryScreen extends StatefulWidget {
  final PostCategory? category;

  const SubCategoryScreen({super.key, this.category});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  final CategoryApiService _apiService = CategoryApiService();

  List<PostSubCategory> _subCategories = const <PostSubCategory>[];
  bool _isLoading = false;
  String? _errorMessage;

  String get _categoryName {
    final String fromCategory = widget.category?.name.trim() ?? '';
    if (fromCategory.isNotEmpty) {
      return fromCategory;
    }
    return 'Category';
  }

  @override
  void initState() {
    super.initState();
    _subCategories =
        widget.category?.subCategories ?? const <PostSubCategory>[];
    if (_subCategories.isEmpty) {
      _loadSubCategories();
    }
  }

  Future<void> _loadSubCategories() async {
    final String categoryId = widget.category?.id.trim() ?? '';
    if (categoryId.isEmpty) {
      setState(() {
        _errorMessage = 'Missing category ID.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PostSubCategory> items = await _apiService.fetchSubCategories(
        categoryId: categoryId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _subCategories = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load sub categories.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CategorySelectionScaffold<PostSubCategory>(
      appBarTitle: 'Choose a Sub Category',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      emptyMessage: 'No sub categories available yet for $_categoryName.',
      items: _subCategories,
      itemTitle: (PostSubCategory item) =>
          item.name.trim().isEmpty ? 'Sub category' : item.name.trim(),
      itemImageUrl: (PostSubCategory item) => item.imageUrl,
      onItemTap: _openCreatePost,
      onRetry: _loadSubCategories,
      itemImageSize: 54,
    );
  }

  void _openCreatePost(PostSubCategory item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostForm(
          initialCategoryId: widget.category?.id,
          initialSubCategoryId: item.id,
        ),
      ),
    );
  }
}
