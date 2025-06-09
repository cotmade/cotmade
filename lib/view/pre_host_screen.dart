import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/login_screen.dart';
import 'package:cotmade/view/signup_screen.dart';
import 'package:cotmade/view/guestScreens/explore_screen.dart';
import 'package:cotmade/view/add_screen.dart';
import 'package:cotmade/view/reels_edite_Screen.dart';
import 'package:cotmade/view/mainpage.dart';
import 'package:cotmade/view/host_home_screen.dart';

class PreHostScreen extends StatefulWidget {
  const PreHostScreen({super.key});

  @override
  State<PreHostScreen> createState() => _PreHostScreenState();
}

class _PreHostScreenState extends State<PreHostScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Get.to(HostHomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              //  tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: Text(""),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
            ],
          ),
          image: DecorationImage(
            image: AssetImage(""),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black12.withOpacity(0.2), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(Colors.black),
                strokeWidth: 10,
              ),
              SizedBox(height: 20),
              const Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  "Switching to Host Mode", //enter text on splash screen
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
