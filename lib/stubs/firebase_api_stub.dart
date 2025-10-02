// lib/services/firebase_api_stub.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 Web BG Message - Not supported here.');
}

class FirebaseApi {
  Future<void> initNotifications() async {
    debugPrint('⚠️ Notifications are not supported on web with this setup.');
  }

  Future<void> uploadPendingFcmToken(String userId) async {
    debugPrint('⚠️ uploadPendingFcmToken skipped on web.');
  }
}
