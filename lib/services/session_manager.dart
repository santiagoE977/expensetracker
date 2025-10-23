// lib/services/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> saveUser(String id, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    await prefs.setString('email', email);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
