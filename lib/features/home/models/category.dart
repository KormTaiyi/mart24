import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/home/data/remote/remote_category.dart';

extension RemoteCategoryUiMapper on RemoteCategory {
  Map<String, String> toUiCategoryItem() {
    final String raw = imageUrl.trim();
    String image = '';
    if (raw.isNotEmpty) {
      if (raw.startsWith('assets/')) {
        image = raw;
      } else {
        final Uri uri = Uri.parse(raw);
        image = uri.hasScheme
            ? raw
            : Uri.parse(ApiConfig.baseUrl).resolve(raw).toString();
      }
    }

    return <String, String>{
      'label': name.trim().isEmpty ? 'Category' : name.trim(),
      'image': image,
    };
  }
}
