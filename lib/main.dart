import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cotmade/firebase_options.dart';
import 'package:cotmade/api/firebase_api.dart';
import 'package:cotmade/view/onboarding_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upgrader/upgrader.dart';
import 'package:app_links/app_links.dart'; // ✅ app_links package
import 'dart:async';

final AppLinks _appLinks = AppLinks(); // ✅ Defined at top level
StreamSubscription<Uri>? _sub;

/// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await handleBackgroundMessage(message);
  debugPrint('🔔 Background message received: ${message.messageId}');
}

/// Handle deep link routing
void handleDeepLink(Uri uri) {
  final host = uri.host;
  final param = uri.queryParameters['param'];
  debugPrint("🔗 Handling link to host: $host, param: $param");

  if (host == 'reel' && param != null) {
    Get.to(() => VideoReelsPage(reelId: param));
  }
}

/// Setup deep linking using `app_links`
Future<void> handleIncomingLinks() async {
  try {
    final Uri? initialUri = await _appLinks.getInitialUri(); // use getInitialUri()
    if (initialUri != null) {
      debugPrint('Initial link: $initialUri');
      handleDeepLink(initialUri);
    }
  } catch (e) {
    debugPrint('❌ Failed to get initial app link: $e');
  }

  _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      debugPrint('Live deep link: $uri');
      handleDeepLink(uri);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseApi().initNotifications();

  await handleIncomingLinks(); // ✅ Start deep link handling

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
    _sub?.cancel(); // Cancel deep link listener
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
          builder: (_, __) => OnboardingScreen(),
        ),
      ),
    );
  }
}
