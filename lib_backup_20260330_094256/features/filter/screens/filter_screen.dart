import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/features/filter/widgets/filter_products_grid_section.dart';
import 'package:mart24/features/home/data/remote/remote_category.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';
import 'package:mart24/features/home/data/remote/remote_product_mapper.dart';
import 'package:mart24/features/home/data/repositories/category_repository_impl.dart';
import 'package:mart24/features/home/data/repositories/product_repository_impl.dart';
import 'package:mart24/features/home/domain/repositories/category_repository.dart';
import 'package:mart24/features/home/domain/repositories/product_repository.dart';
import 'package:mart24/features/home/models/category.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/shared/widgets/category_section.dart';
import 'package:mart24/shared/widgets/search_app_bar.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final CategoryRepository _categoryRepository = CategoryRepositoryImpl();
  final ProductRepository _productRepository = ProductRepositoryImpl();

  List<Map<String, String>>? _remoteCategories;
  List<Product>? _remoteProducts;
  bool _isLoadingProducts = false;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final List<RemoteCategory> categories = await _categoryRepository
          .fetchActiveCategories(page: 1, limit: 50);
      final List<Map<String, String>> mapped = categories
          .map((remote) => remote.toUiCategoryItem())
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteCategories = mapped;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteCategories = const <Map<String, String>>[];
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final PaginatedResponse<RemoteProduct> response = await _productRepository
          .fetchProducts(page: 1, limit: 24);
      final List<Product> mapped = <Product>[];
      for (final RemoteProduct remote in response.items) {
        try {
          mapped.add(remote.toUiProduct());
        } catch (error) {
          if (kDebugMode) {
            debugPrint('[FILTER] skipping malformed product: $error');
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteProducts = mapped;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productsError = 'Unable to load products.';
        _remoteProducts = const <Product>[];
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingProducts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories =
        _remoteCategories ?? const <Map<String, String>>[];
    final List<Product> products = _remoteProducts ?? const <Product>[];

    return Scaffold(
      appBar: const SearchAppBar(
        fallbackBackRoute: AppRoutes.search,
        showFilterIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            CategorySection(isGrid: true, items: categories),
            // const SizedBox(height: 20),
            if (_isLoadingProducts)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_productsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _productsError!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            FilterProductsGridSection(products: products),
          ],
        ),
      ),
    );
  }
}
