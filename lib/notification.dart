import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final _andriodChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for importance notification',
    importance: Importance.defaultImportance,
  );

  final _localNotification = FlutterLocalNotificationsPlugin();

  void initMessaging() {
    _firebaseMessaging.requestPermission(
      sound: true,
      badge: true,
      alert: true,
    );

    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
      // Save the token or send it to the server for future use
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _andriodChannel.id,
            _andriodChannel.name,
            channelDescription: _andriodChannel.description,
            icon: '@drawable/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Handle the notification here, such as displaying it to the user
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Handle the notification here, such as navigating to a specific screen
      }
    });

    // Future initLocalNotifications() async {
    //   const iOS = IOSInitializationSettings();
    //   const andriod = AndroidInitializationSettings('@drawable/ic_launcher');
    //   const settings = InitializationSettings(android: andriod);
    //
    //   await _localNotification.initialize(settings, onSelectNotification: (payload) {
    //     final message = RemoteMessage.fromMap(jsonDecode(payload);
    //     handl)
    //   });
    // }
  }
}