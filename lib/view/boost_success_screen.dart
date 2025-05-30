import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/view/hostScreens/my_postings_screen.dart';

class BoostScreen extends StatefulWidget {
  @override
  _BoostScreenState createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove default back button
          title: Text(""),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Get.offAll(() => MyPostingsScreen()); // Navigate to home screen
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'images/hurray.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "You have successfully boosted this property!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "This property is now on premium plan for the next 30 days.",
              ),
              SizedBox(height: 10),
              Card(
                color: Color(0xFFC5E1A5),
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 30, color: Color(0xFF689F38)),
                      SizedBox(width: 10),
                      Text(
                        "Congratulations !!!",
                        style: TextStyle(color: Color(0xFF689F38)),
                      ),
                    ],
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
