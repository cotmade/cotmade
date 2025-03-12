import 'package:cotmade/view/guestScreens/account_screen.dart';
import 'package:cotmade/view/guestScreens/inbox_screen.dart';
import 'package:cotmade/view/guestScreens/saved_listings_screen.dart';
import 'package:cotmade/view/guestScreens/trips_screen.dart';
import 'package:cotmade/view/hostScreens/bookings_screen.dart';
import 'package:cotmade/view/hostScreens/my_postings_screen.dart';
import 'package:flutter/material.dart';

class HostHomeScreen extends StatefulWidget {
  int? index;

  HostHomeScreen({
    super.key,
    this.index,
  });

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  int selectedIndex = 0;

  final List<String> screenTitles = [
    'Bookings',
    'My Postings',
    'Inbox',
    'Profile',
  ];

  final List<Widget> screens = [
    BookingsScreen(),
    MyPostingsScreen(),
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
  void initState() {
    super.initState();
    selectedIndex = widget.index ?? 3;
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
        selectedItemColor: Colors.pinkAccent, // Active color
        unselectedItemColor: Colors.black, // Inactive color
        items: <BottomNavigationBarItem>[
          customNavigationBarItem(0, Icons.calendar_today, screenTitles[0]),
          customNavigationBarItem(1, Icons.home, screenTitles[1]),
          customNavigationBarItem(2, Icons.message, screenTitles[2]),
          customNavigationBarItem(3, Icons.person_outline, screenTitles[3]),
        ],
      ),
    );
  }
}
