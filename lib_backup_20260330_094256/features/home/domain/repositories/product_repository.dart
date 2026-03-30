import 'package:mart24/core/network/paginated_response.dart';
import 'package:mart24/features/home/data/remote/remote_product.dart';

abstract class ProductRepository {
  Future<PaginatedResponse<RemoteProduct>> fetchProducts({
    int page,
    int limit,
    String? search,
    int? categoryId,
    String status,
    double? latitude,
    double? longitude,
  });
}
