import 'package:cotmade/api/firebase_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cotmade/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/onboarding_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upgrader/upgrader.dart';
import 'dart:io';

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await handleBackgroundMessage(message);
  debugPrint('🔔 Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission (Android 13+ and iOS)
  await FirebaseMessaging.instance.requestPermission();

  // ✅ Initialize Firebase Messaging and Notifications
  await FirebaseApi().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CotMade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.black),
          color: Color(0xcaf6f6f6),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent)
            .copyWith(background: Colors.white),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.pinkAccent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: UpgradeAlert(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => OnboardingScreen(),
        ),
      ),
    );
  }
}
