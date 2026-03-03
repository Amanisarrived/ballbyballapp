import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreference {
  static const String _statusKey = 'notification_permission_status';
  static const String _deniedCountKey = 'notification_denied_count';
  static const int maxDeniedCount = 3;

  // Save granted — never show screen again
  static Future<void> saveGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, 'granted');
  }

  // Save denied — increment count
  static Future<void> saveDenied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, 'denied');
    final count = prefs.getInt(_deniedCountKey) ?? 0;
    await prefs.setInt(_deniedCountKey, count + 1);
  }

  // Check if user already granted
  static Future<bool> isGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_statusKey) == 'granted';
  }

  // How many times user denied
  static Future<int> getDeniedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_deniedCountKey) ?? 0;
  }

  // Should we show permission screen?
  static Future<bool> shouldShowPermissionScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_statusKey);
    final deniedCount = prefs.getInt(_deniedCountKey) ?? 0;

    if (status == 'granted') return false;         // already allowed
    if (deniedCount >= maxDeniedCount) return false; // denied too many times
    return true;                                    // show screen
  }
}