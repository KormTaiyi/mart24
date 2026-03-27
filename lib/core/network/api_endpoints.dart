class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.e.2m-sy.com/api',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String healthCheck = '/health';

  static const String registerClient = '/auth/register/client';
  static const String loginClient = '/auth/login';
  static const String googleLoginClient = '/auth/google/login/client';
  static const String googleRegisterClient = '/auth/google/register/client';
  static const String googleRegisterStaff = '/auth/google/register/staff';
  static const String phoneLoginFirebase = '/auth/phone/login/firebase';

  static const String login = loginClient;
  static const String register = registerClient;
  static const String refreshToken = '/auth/refresh-token';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';

  static const String profile = '/users/me';
  static const String myPosts = '/posts/me';
  static const String publicPosts = '/posts';
  static const String createPost = '/posts';
  static String updateMyPost(String postId) => '/posts/$postId';
  static String deleteMyPost(String postId) => '/posts/$postId';
  static String toggleLike(String postId) => '/posts/$postId/like';

  static const String products = '/products';
  static String productById(String id) => '/products/$id';

  static const String categories = '/categories';
  static const String publicCategories = '/categories';
  static const String activeCategories = '/categories/active';
  static String subCategoriesByCategory(String categoryId) =>
      '/categories/$categoryId/sub-categories';

  static const String banners = '/banners';
  static const String activeBanners = '/banners/active';
}
