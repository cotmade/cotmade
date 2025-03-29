import 'package:flutter/material.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/privacy_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cotmade/view/login_screen2.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';
import 'package:cotmade/view/guestScreens/help_centre.dart';
import 'package:cotmade/view/guestScreens/terms_of_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

// Sign out function
signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    Get.snackbar("Logged Out", "You have successfully logged out");
    Get.offAll(() => FirstScreen());
  } catch (e) {
    Get.snackbar("Error", "An error occurred while signing out.");
  }
}

class _SettingScreenState extends State<SettingScreen> {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 18,
              child: CircleAvatar(
                backgroundImage: AppConstants.currentUser.displayImage,
                radius: 17,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            // Personal Information button
            Text('Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: const Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.black),
                  title: const Text("Contact Help Centre",
                      style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    Get.to(() => HelpCentreScreen());
                  },
                ),
              ),
            ),
            // FAQ button
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: const Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                  leading: const Icon(Icons.book_online, color: Colors.black),
                  title: const Text("How CotMade works",
                      style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    // Get.to(FaqScreen());
                  },
                ),
              ),
            ),
            SizedBox(height: 30),
            // Logout button
            Text('Legal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: const Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                  leading: const Icon(Icons.document_scanner_outlined,
                      color: Colors.black),
                  title: const Text("Privacy Policy",
                      style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    Get.to(PrivacyScreen());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: const Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                  leading: const Icon(Icons.document_scanner_outlined,
                      color: Colors.black),
                  title: const Text("Terms of Service",
                      style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    Get.to(TermsOfServiceScreen());
                  },
                ),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                  leading: Icon(Icons.logout_outlined, color: Colors.black),
                  title: Text("Log out", style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    signOut();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
