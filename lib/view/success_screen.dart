import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guest_home_screen.dart';

class SuccessScreen extends StatefulWidget {
  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
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
                Get.offAll(() => GuestHomeScreen()); // Navigate to home screen
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
                "You have successfully booked a COT!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "You can now chat with the property host.\n\n"
                "Do not do any other transactions with the host outside the platform.",
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
