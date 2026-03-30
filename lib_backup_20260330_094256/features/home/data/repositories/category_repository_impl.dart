import 'package:mart24/features/home/data/remote/categories_api_service.dart';
import 'package:mart24/features/home/data/remote/remote_category.dart';
import 'package:mart24/features/home/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({CategoriesApiService? apiService})
    : _apiService = apiService ?? CategoriesApiService();

  final CategoriesApiService _apiService;

  @override
  Future<List<RemoteCategory>> fetchActiveCategories({
    int page = 1,
    int limit = 10,
    String? search,
  }) {
    return _apiService.fetchActiveCategories(
      page: page,
      limit: limit,
      search: search,
    );
  }
}
