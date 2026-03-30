import 'package:mart24/features/home/data/remote/banners_api_service.dart';
import 'package:mart24/features/home/data/remote/remote_banner.dart';
import 'package:mart24/features/home/domain/repositories/banner_repository.dart';

class BannerRepositoryImpl implements BannerRepository {
  BannerRepositoryImpl({BannersApiService? apiService})
    : _apiService = apiService ?? BannersApiService();

  final BannersApiService _apiService;

  @override
  Future<List<RemoteBanner>> fetchActiveBanners({String position = 'top'}) {
    return _apiService.fetchActiveBanners(position: position);
  }
}
