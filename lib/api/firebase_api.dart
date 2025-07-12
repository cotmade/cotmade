import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import '../model/app_constants.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    debugPrint('User permission status: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await _firebaseMessaging.setAutoInitEnabled(true);

      var token = await _firebaseMessaging.getAPNSToken();
      if (token == null) {
        await Future<void>.delayed(const Duration(seconds: 3));
        token = await _firebaseMessaging.getAPNSToken();
      }
    }

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    if (fcmToken != null &&
        AppConstants.currentUser != null &&
        AppConstants.currentUser.id != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AppConstants.currentUser.id)
          .update({'fcmToken': fcmToken});
    }
  }
}

