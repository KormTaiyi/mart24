import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/features/home/data/remote/remote_banner.dart';

extension RemoteBannerUiMapper on RemoteBanner {
  String toUiBannerImage() {
    final String raw = imageUrl.trim();
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

    final Uri base = Uri.parse(ApiConfig.baseUrl);
    return base.resolve(raw).toString();
  }
}
