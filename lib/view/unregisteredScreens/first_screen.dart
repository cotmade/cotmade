import 'package:cotmade/view/guestScreens/account_screen.dart';
import 'package:cotmade/view/guestScreens/explore_screen.dart';
import 'package:cotmade/view/guestScreens/inbox_screen.dart';
import 'package:cotmade/view/guestScreens/saved_listings_screen.dart';
import 'package:cotmade/view/guestScreens/trips_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/guestScreens/property_reels_screen.dart';
//import 'package:cotmade/view/reelsScreen.dart';
import 'package:cotmade/view/guestScreens/trip_screen.dart';
import 'package:cotmade/view/login_screen.dart';
import 'package:cotmade/view/unregisteredScreens/first_explore.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:cotmade/view/unregisteredScreens/faq_page.dart';
import 'package:cotmade/view/unregisteredScreens/view_video_screen.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  int selectedIndex = 0;

  final List<String> screenTitles = [
    'Login',
    'Explore',
    'FAQ',
  ];

  final List<Widget> screens = [
    LoginScreen(),
    FirstExplore(),
    FaqPage(),
  ];

  BottomNavigationBarItem customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        color: Colors.black,
      ),
      activeIcon: Icon(
        iconData,
        color: Colors.pinkAccent,
      ),
      label: title,
    );
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
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: Text(
          screenTitles[selectedIndex],
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [],
      ),
      body: screens[selectedIndex],
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        onTap: (i) {
          setState(() {
            selectedIndex = i;
          });
        },
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          customNavigationBarItem(0, Icons.login_rounded, screenTitles[0]),
          customNavigationBarItem(1, Icons.search, screenTitles[1]),
          customNavigationBarItem(
              2, Icons.question_mark_rounded, screenTitles[2]),
        ],
      ),
    );
  }
}
