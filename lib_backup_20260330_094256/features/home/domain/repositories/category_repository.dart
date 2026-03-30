import 'package:mart24/features/home/data/remote/remote_category.dart';

abstract class CategoryRepository {
  Future<List<RemoteCategory>> fetchActiveCategories({
    int page,
    int limit,
    String? search,
  });
}
