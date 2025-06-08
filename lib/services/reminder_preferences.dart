import 'package:shared_preferences/shared_preferences.dart';

class ReminderPreferences {
  static const String _dailyReminderTimeKey = 'daily_reminder_time';
  static const String _weeklyReminderTimeKey = 'weekly_reminder_time';
  static const String _remindersEnabledKey = 'reminders_enabled';

  static Future<void> setDailyReminderTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyReminderTimeKey, time.toIso8601String());
  }

  static Future<DateTime?> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_dailyReminderTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<void> setWeeklyReminderTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyReminderTimeKey, time.toIso8601String());
  }

  static Future<DateTime?> getWeeklyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_weeklyReminderTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);
  }

  static Future<bool> getRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? false;
  }
}
