import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    if (Platform.isIOS) {
      // Explicitly ask for permission and register with APNs
      await _firebaseMessaging.setAutoInitEnabled(true);

      var token = await _firebaseMessaging.getAPNSToken();
      if (token == null) {
        await Future<void>.delayed(const Duration(seconds: 3));
        token = await _firebaseMessaging.getAPNSToken();
      }
    }

    // Now get the FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('Token: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}
