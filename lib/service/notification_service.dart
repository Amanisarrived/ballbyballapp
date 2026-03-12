import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );


    final token = await _firebaseMessaging.getToken();
    debugPrint(" FCM Token: $token");


    await FirebaseMessaging.instance.subscribeToTopic("cricket_notification");
    debugPrint(" Subscribed to cricket_notification");

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(" Notification clicked: ${response.payload}");
      },
    );


    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(message);
    });


    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(" App opened from background");
    });


    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(" App opened from terminated state");
    }
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'cricket_channel',
      'Cricket Updates',
      channelDescription: 'Match updates & alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFCC0000),
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
    );
  }
}