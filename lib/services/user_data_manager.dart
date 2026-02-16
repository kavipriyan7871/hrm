import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataManager {
  static const String _userKeyPrefix = 'user_data_';

  // Helper to get current user ID
  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming 'uid' is stored as int based on usage in other files
    int? uidInt = prefs.getInt('uid');
    if (uidInt != null && uidInt != 0) return uidInt.toString();

    // Fallback if stored as string
    String? uidStr = prefs.getString('uid');
    if (uidStr != null && uidStr.isNotEmpty && uidStr != "0") return uidStr;

    return null;
  }

  /// Retrieves a list of maps for the current user
  static Future<List<Map<String, dynamic>>?> getCurrentUserList(
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = await _getCurrentUserId();

    if (uid == null) {
      // If no user logged in, return null or empty? Start with null to signify no data context.
      return null;
    }

    final fullKey = '${_userKeyPrefix}${uid}_$key';
    final jsonString = prefs.getString(fullKey);

    if (jsonString == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      // Ensure elements are Map<String, dynamic>
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decoding user list for key $fullKey: $e');
      return null;
    }
  }

  /// Saves a list of maps for the current user
  static Future<void> saveCurrentUserList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = await _getCurrentUserId();

    if (uid == null) {
      print('Cannot save user list: No active user ID found');
      return;
    }

    final fullKey = '${_userKeyPrefix}${uid}_$key';
    try {
      final jsonString = jsonEncode(list);
      await prefs.setString(fullKey, jsonString);
    } catch (e) {
      print('Error encoding user list for key $fullKey: $e');
    }
  }
}
