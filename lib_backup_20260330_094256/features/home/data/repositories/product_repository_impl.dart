import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/features/home/data/remote/products_api_service.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';
import 'package:mart24/features/home/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({ProductsApiService? apiService})
    : _apiService = apiService ?? ProductsApiService();

  final ProductsApiService _apiService;

  @override
  Future<PaginatedResponse<RemoteProduct>> fetchProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    String status = 'active',
    double? latitude,
    double? longitude,
  }) {
    return _apiService.fetchProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      status: status,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
