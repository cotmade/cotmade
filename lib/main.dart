import 'dart:async';

import 'package:cotmade/api/firebase_api.dart';
import 'package:cotmade/firebase_options.dart';
import 'package:cotmade/view/onboarding_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:upgrader/upgrader.dart';

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

/// GoRouter configuration with deep link routes
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => OnboardingScreen(),
    ),
    GoRoute(
      path: '/reel',
      builder: (context, state) {
        final reelId = state.queryParams['param'];
        if (reelId == null) {
          return const Scaffold(
            body: Center(child: Text('Missing reel ID')),
          );
        }
        return VideoReelsPage(reelId: reelId);
      },
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found')),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await FirebaseApi().initNotifications();

  // Run app with GoRouter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) {
          return MaterialApp.router(
            routerConfig: router,
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
          );
        },
      ),
    );
  }
}
