import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();

  static Future<bool?> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final String? raw = await getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> setJsonMap(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }
}
