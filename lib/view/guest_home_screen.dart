import 'package:cotmade/view/guestScreens/account_screen.dart';
import 'package:cotmade/view/guestScreens/explore_screen.dart';
import 'package:cotmade/view/guestScreens/inbox_screen.dart';
import 'package:cotmade/view/guestScreens/saved_listings_screen.dart';
import 'package:cotmade/view/guestScreens/trip_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/guestScreens/property_reels_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  // Set the initial selectedIndex to 5 to display VideoReelsPage initially
  int selectedIndex = 5;

  final List<String> screenTitles = [
    'Explore',
    'Saved',
    'Trips',
    'Inbox',
    'Profile',
  ];

  final List<Widget> screens = [
    ExploreScreen(),
    SavedListingsScreen(),
    TripScreen(),
    InboxScreen(),
    AccountScreen(),
  ];

  BottomNavigationBarItem customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        color: selectedIndex == index ? Colors.pinkAccent : Colors.black,
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
          // Only show titles for the regular screens
          selectedIndex < 5 ? screenTitles[selectedIndex] : '',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            iconSize: 25.0,
            icon: Icon(Icons.video_collection_rounded),
            onPressed: () {
              // Navigate directly to VideoReelsPage when clicked
              Get.to(VideoReelsPage());
            },
            color: Colors.black,
          ),
        ],
      ),
      body: selectedIndex == 5
          ? VideoReelsPage() // Show VideoReelsPage if the selectedIndex is 5
          : screens[selectedIndex], // Otherwise, show the selected screen
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
        selectedItemColor: Colors.pinkAccent, // Set active item color
        unselectedItemColor: Colors.black, // Set inactive item color
        items: <BottomNavigationBarItem>[
          customNavigationBarItem(0, Icons.search, screenTitles[0]),
          customNavigationBarItem(1, Icons.favorite_border, screenTitles[1]),
          customNavigationBarItem(2, Icons.hotel, screenTitles[2]),
          customNavigationBarItem(3, Icons.message, screenTitles[3]),
          customNavigationBarItem(4, Icons.person_outline, screenTitles[4]),
        ],
      ),
    );
  }
}
