import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'bible_reading_reminder',
          channelName: 'Bible Reading Reminders',
          channelDescription: 'Notifications for daily Bible reading reminders',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'weekly_summary',
          channelName: 'Weekly Reading Summary',
          channelDescription: 'Weekly summary of Bible reading progress',
          defaultColor: Colors.green,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'event_reminders',
          channelName: 'Event Reminders',
          channelDescription: 'Notifications for upcoming events',
          defaultColor: Colors.deepPurple,
          importance: NotificationImportance.High,
          playSound: true,
        ),
      ],
    );
  }

  Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> scheduleReadingReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'bible_reading_reminder',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> scheduleWeeklySummary({
    required TimeOfDay time,
    required int weekday,
    required int completedDays,
    required int totalDays,
  }) async {
    final percentage = ((completedDays / totalDays) * 100).toStringAsFixed(1);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'weekly_summary',
        title: 'Weekly Reading Progress',
        body:
            'You\'ve completed $completedDays out of $totalDays readings ($percentage%)',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        weekday: weekday,
        hour: time.hour,
        minute: time.minute,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> scheduleEventReminder({
    required int id,
    required DateTime eventTime,
    required String title,
    required String body,
  }) async {
    // Schedule 15 minutes before
    final reminderTime = eventTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) {
      // If event is very soon or past, schedule for 1 min from now or don't schedule
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'event_reminders',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar.fromDate(
        date: reminderTime,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> cancelReadingReminder() async {
    await AwesomeNotifications().cancel(1);
  }

  Future<void> cancelWeeklySummary() async {
    await AwesomeNotifications().cancel(999);
  }
}
