import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_constants.dart';
import 'package:cotmade/model/user_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// Background message handler — must be a top-level function
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 BG Message - Title: ${message.notification?.title}');
  debugPrint('🔔 BG Message - Body: ${message.notification?.body}');
  debugPrint('🔔 BG Message - Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initNotifications() async {
    try {
      // Step 1: Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission();
      debugPrint('📲 User permission status: ${settings.authorizationStatus}');

      // Step 2: iOS-specific
      if (Platform.isIOS) {
        await _firebaseMessaging.setAutoInitEnabled(true);
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
        debugPrint('🍏 APNs Token: $apnsToken');
      }

      // Step 3: Init local notifications
      await _initLocalNotifications();

      // Step 4: Get and save FCM token
      final fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔥 FCM Token: $fcmToken');

      if (fcmToken != null &&
          AppConstants.currentUser != null &&
          AppConstants.currentUser.id != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(AppConstants.currentUser.id)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        debugPrint('✅ FCM token uploaded to Firestore');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingFcmToken', fcmToken ?? '');
        debugPrint('💾 FCM token saved locally for later');
      }

      // Step 5: Foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 Foreground message received: ${message.notification?.title}');
        await _showLocalNotification(message);
      });

      // Step 6: Tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 Notification was opened!');
        // Handle navigation or logic
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error during FCM init: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Show local notification manually (for foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'foreground_channel', // Channel ID
      'Foreground Notifications', // Channel name
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformDetails,
    );
  }

  /// Init local notifications plugin
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// Upload pending FCM token saved before login
  Future<void> uploadPendingFcmToken(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('pendingFcmToken');

      if (savedToken != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': savedToken});

        debugPrint('✅ Token uploaded to Firestore');
        await prefs.remove('pendingFcmToken');
      } else {
        debugPrint('⚠️ Token or User ID not valid. Skipping upload.');
      }
    } catch (e) {
      debugPrint('❌ Error uploading FCM token: $e');
    }
  }
}
