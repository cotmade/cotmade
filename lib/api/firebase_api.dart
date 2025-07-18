import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/app_constants.dart';

/// Background message handler (also used in main.dart)
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 BG Message - Title: ${message.notification?.title}');
  debugPrint('🔔 BG Message - Body: ${message.notification?.body}');
  debugPrint('🔔 BG Message - Payload: ${message.data}');
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and local notifications
  Future<void> initNotifications() async {
    try {
      // 🔹 Step 1: Request permission (iOS + Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('📲 User permission status: ${settings.authorizationStatus}');

      // 🔹 Step 1.5: Android 13+ explicit permission
      if (Platform.isAndroid) {
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          debugPrint('🔔 Android 13+ permission granted: ${status.isGranted}');
        }
      }

      // 🔹 Step 2: Foreground presentation (iOS only)
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 🔹 Step 3: Handle APNs (iOS only)
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

      // 🔹 Step 5: Get and save FCM token
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

      // 🔹 Step 6: Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 Foreground message: ${message.notification?.title}');
        await _showLocalNotification(message);
      });

      // 🔹 Step 7: Notification tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 Notification tapped!');
        // TODO: Add navigation or logic
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Show notification manually
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'foreground_channel',
      'Foreground Notifications',
      channelDescription: 'Notifications when app is in foreground',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? message.data['title'] ?? 'Notification',
      message.notification?.body ?? message.data['body'] ?? '',
      notificationDetails,
    );
  }

  /// Initialize local notifications and create Android channel
  Future<void> _initLocalNotifications() async {
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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

    // 🔹 Create Android channel manually
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'foreground_channel',
      'Foreground Notifications',
      description: 'Channel for foreground notifications',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Upload pending FCM token after login
  Future<void> uploadPendingFcmToken(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('pendingFcmToken');

      if (savedToken != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': savedToken});
        debugPrint('✅ Pending token uploaded to Firestore');
        await prefs.remove('pendingFcmToken');
      } else {
        debugPrint('⚠️ No valid pending token or user ID.');
      }
    } catch (e) {
      debugPrint('❌ Error uploading pending token: $e');
    }
  }
}
