import 'package:cotmade/api/firebase_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cotmade/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/splash_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cotmade/view/reelsScreen.dart';
//import 'package:cotmade/view/try_screen.dart';
import 'package:cotmade/view/onboarding_screen.dart';
import 'dart:ui';
import 'package:upgrader/upgrader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Application name
      title: 'CotMade',
      debugShowCheckedModeBanner: false,
      // Application theme data, you can set the colors for the application as
      // you want
      theme: ThemeData(
        brightness: Brightness.light, // Make sure it's light theme
        primaryColor: Colors.black, // Set the primary color to white
        scaffoldBackgroundColor:
            Colors.white, // Set the scaffold background to white
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
              color: Colors
                  .black), // Black icons for visibility on white background
          color: Color(0xcaf6f6f6), // Set app bar background to white
          elevation: 0, // Optional: remove app bar shadow for a clean look
        ),
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.pinkAccent).copyWith(
          background: Colors
              .white, // Set background color to white for the color scheme
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                Colors.pinkAccent, // Text color (was 'primary' before)
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.white, // Background color (was 'primary' before)
            foregroundColor: Colors.black, // Text color
          ),
        ),
      ),
      // A widget which will be started on application startup
      home: UpgradeAlert(
          child: ScreenUtilInit(
              designSize: Size(375, 812), child: OnboardingScreen()),
        ));
  }
}
