import 'package:flutter/material.dart';
import 'package:mart24/features/account/screens/account_screen.dart';
import 'package:mart24/features/account/screens/edit_profile_screen.dart';
import 'package:mart24/features/account/screens/setting_screen.dart';
import 'package:mart24/features/account/screens/view_profile_screen.dart';
import 'package:mart24/features/auth/screens/forgot_password_screen.dart';
import 'package:mart24/features/auth/screens/otp_screen.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/category/screen/category_screen.dart';
import 'package:mart24/features/category/screen/sub_category_screen.dart';
import 'package:mart24/features/chat/screens/list_chat_screen.dart';
import 'package:mart24/features/filter/screens/filter_screen.dart';
import 'package:mart24/features/notification/screens/notification_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/features/search/screens/search_screen.dart';
import 'package:mart24/shared/widgets/app_bottom_bar.dart';

class AppRoutes {
  static const String home = '/';
  static const String account = '/account';
  static const String notification = '/notification';
  static const String sell = '/sell';
  static const String category = '/category';
  static const String subCategory = '/sub-category';
  static const String login = '/login';
  static const String register = '/register';
  static const String search = '/search';
  static const String filter = '/filter';
  static const String forgotPassword = '/forgot_password';
  static const String otp = '/otp';
  static const String setting = '/setting';
  static const String viewProfile = '/view_profile';
  static const String editProfile = '/edit_profile';
  static const String listChat = '/list_chat';
  static const String createPost = '/create-post';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => AppBottomBar(),
    account: (context) => AccountScreen(),
    notification: (context) => NotificationScreen(),
    // sell: (context) => SellScreen(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    search: (context) => SearchScreen(),
    category: (context) => CategoryScreen(),
    subCategory: (context) => SubCategoryScreen(),
    filter: (context) => FilterScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    otp: (context) => OtpScreen(),
    setting: (context) => SettingScreen(),
    viewProfile: (context) => ViewProfileScreen(),
    editProfile: (context) => EditProfileScreen(),
    listChat: (context) => ListChatScreen(),
    createPost: (context) => CategoryScreen(),
  };
}
