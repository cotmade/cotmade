import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/view/login_screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const GuestHomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),

      //StreamBuilder<User?>(
      //  stream: FirebaseAuth.instance.authStateChanges(),
      //  builder: (context, snapshot) {
      //    if (snapshot.hasData) {
      //      return GuestHomeScreen();
      //   } else {
      //      return LoginScreen();
      //   }
      //  },
    );
  }
}
