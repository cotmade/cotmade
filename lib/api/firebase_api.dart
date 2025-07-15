import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_constants.dart';
import 'package:cotmade/model/user_model.dart';

/// Background message handler — must be a top-level function
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 BG Message - Title: ${message.notification?.title}');
  debugPrint('🔔 BG Message - Body: ${message.notification?.body}');
  debugPrint('🔔 BG Message - Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize Firebase Messaging
  Future<void> initNotifications() async {
    try {
      // Step 1: Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission();
      debugPrint('📲 User permission status: ${settings.authorizationStatus}');

      // Step 2: For iOS — get APNs token
      if (Platform.isIOS) {
        await _firebaseMessaging.setAutoInitEnabled(true);

        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
        debugPrint('🍏 APNs Token: $apnsToken');
      }

      // Step 3: Get FCM token
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
        // Save locally to upload after login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingFcmToken', fcmToken ?? '');
        debugPrint('💾 FCM token saved locally for later');
      }

      // Register foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground message received: ${message.notification?.title}');
        // TODO: Show local notification if needed
      });

      // Register notification tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 Notification was opened!');
        // TODO: Handle navigation or app logic on notification tap
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error during FCM init: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Call this method **after login** to sync any saved token
  Future<void> uploadPendingFcmToken(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('pendingFcmToken');

      debugPrint('📍 uploadPendingFcmToken()');
      debugPrint('👉 Token: $savedToken');
      debugPrint('👉 User ID: $userId');

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
