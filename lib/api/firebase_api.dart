// lib/services/firebase_api_mobile.dart
export '../stubs/firebase_api_stub.dart'
    if (dart.library.io) 'firebase_api_mobile.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_constants.dart';
import '../model/user_model.dart';

/// Background message handler
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 BG Message - Title: ${message.notification?.title}');
  debugPrint('🔔 BG Message - Body: ${message.notification?.body}');
  debugPrint('🔔 BG Message - Payload: ${message.data}');
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging and Notifications for iOS/Android
  Future<void> initNotifications() async {
    try {
      // 🔹 Step 1: Request permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('📲 User permission status: ${settings.authorizationStatus}');

      // 🔹 Step 2: Set foreground options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 🔹 Step 3: Handle APNs token (iOS-specific)
      if (Platform.isIOS) {
        await _firebaseMessaging.setAutoInitEnabled(true);
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
        debugPrint('🍏 APNs Token: $apnsToken');
      }

      // 🔹 Step 4: Init local notifications
      await _initLocalNotifications();

      // 🔹 Step 5: Get FCM token
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
        debugPrint('💾 FCM token saved locally');
      }

      // 🔹 Step 6: Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 Foreground message: ${message.notification?.title}');
        await _showLocalNotification(message);
      });

      // 🔹 Step 7: Handle taps on notifications
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 Notification tapped!');
        // TODO: Navigate or handle tap action
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error during Firebase notification init: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Show local notification manually
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      iOS: iOSDetails,
      android: AndroidNotificationDetails(
        'foreground_channel',
        'Foreground Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? message.data['title'] ?? 'Notification',
      message.notification?.body ?? message.data['body'] ?? '',
      platformDetails,
    );
  }

  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
    debugPrint('✅ Local notifications initialized');
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
