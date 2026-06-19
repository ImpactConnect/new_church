import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Request Permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted permission');
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
        return;
      }

      // 2. Initialize Local Notifications (For Foreground)
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(initializationSettings);

      // 3. Setup Android Channel for heads-up notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.high,
      );

      final localNotifAndroid =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await localNotifAndroid?.createNotificationChannel(channel);

      // 4. Update iOS Foreground Notification Options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Got a message whilst in the foreground!');
        if (message.notification != null) {
          _showLocalNotification(message, channel);
        }
      });

      // 6. Subscribe to Global Broadcasts
      await _firebaseMessaging.subscribeToTopic('all');
      debugPrint('FCM: Subscribed to topic "all"');

      // 7. Get token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: \$token');
    } catch (e) {
      debugPrint('Error initializing FCM: \$e');
    }
  }

  static void _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) {
    _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
