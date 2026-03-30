import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';
import 'package:mart24/features/home/data/remote/remote_product_mapper.dart';
import 'package:mart24/features/home/data/repositories/product_repository_impl.dart';
import 'package:mart24/features/home/domain/repositories/product_repository.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/features/search/widgets/popular_section.dart';
import 'package:mart24/features/search/widgets/popular_search.dart';
import 'package:mart24/shared/widgets/search_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductRepository _productRepository = ProductRepositoryImpl();

  List<Product> _products = const <Product>[];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
            debugPrint('[SEARCH] skipping malformed product: $error');
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _products = mapped;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load products.';
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SearchAppBar(fallbackBackRoute: AppRoutes.home),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopularSearch(items: _buildPopularSearchTerms(_products)),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            PopularSection(title: 'Popular products', products: _products),
          ],
        ),
      ),
    );
  }

  List<String> _buildPopularSearchTerms(List<Product> products) {
    final Set<String> terms = <String>{};

    void addTerms(String source) {
      final List<String> parts = source
          .split(' ')
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.length >= 3)
          .toList();

      for (final String part in parts) {
        terms.add(part);
        if (terms.length >= 12) {
          return;
        }
      }
    }

    for (final Product product in products) {
      addTerms(product.name);
      if (terms.length >= 12) {
        break;
      }
      addTerms(product.brand);
      if (terms.length >= 12) {
        break;
      }
    }

    return terms.toList();
  }
}
