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
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:cotmade/view/video_reels_screen.dart';

StreamSubscription? _sub;

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

/// Handle deep links
void handleIncomingLinks() {
  // Cold start
  getInitialUri().then((uri) {
    if (uri != null) {
      debugPrint('📦 Initial deep link: $uri');
      handleDeepLink(uri);
    }
  });

  // While app is running
  _sub = uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      debugPrint('📲 Live deep link: $uri');
      handleDeepLink(uri);
    }
  }, onError: (err) {
    debugPrint('❌ Deep link error: $err');
  });
}

/// Parse and act on deep link
void handleDeepLink(Uri uri) {
  final host = uri.host;
  final param = uri.queryParameters['param'];

  debugPrint("🔗 Handling link to host: $host, param: $param");

  if (host == 'reel' && param != null) {
    Get.to(() => VideoReelsPage(reelId: param));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Register first
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Then init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize messaging
  await FirebaseApi().initNotifications();

  // Start listening for deep links
  handleIncomingLinks();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
