import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import '../model/app_constants.dart';

/// This function handles background FCM messages on Android.
/// It must be a top-level function (not inside a class).
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 BG Message - Title: ${message.notification?.title}');
  debugPrint('🔔 BG Message - Body: ${message.notification?.body}');
  debugPrint('🔔 BG Message - Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize FCM permissions and token registration
  Future<void> initNotifications() async {
    try {
      // Step 1: Request notification permissions (for iOS and Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission();
      debugPrint('📲 User permission status: ${settings.authorizationStatus}');

      // Step 2: (iOS only) Enable auto-init and fetch APNs token
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

      // Step 4: Save token to Firestore if user is initialized
      if (fcmToken != null &&
          AppConstants.currentUser != null &&
          AppConstants.currentUser.id != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(AppConstants.currentUser.id)
            .update({'fcmToken': fcmToken});
        debugPrint('✅ FCM token updated in Firestore');
      } else {
        debugPrint('⚠️ User not logged in yet, skipping Firestore update');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during FCM initialization: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
