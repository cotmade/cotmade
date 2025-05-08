import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/add_video_button.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/view/host_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/faq_screen.dart';
import 'package:cotmade/view/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cotmade/view/add_screen.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/guestScreens/person_details.dart';
import 'package:cotmade/view/pre_guest_screen.dart';
import 'package:cotmade/view/pre_host_screen.dart';
import 'package:cotmade/view/hostScreens/video_upload.dart';
import 'package:cotmade/view/login_screen2.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';
import 'package:cotmade/view/login_screen.dart';
import 'package:cotmade/view/guestScreens/document_upload_screen.dart';
import 'package:cotmade/view/settings_screen.dart';
import 'package:cotmade/view/guestScreens/feedback_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Default button title
  String _hostingTitle = 'List your Property';
  bool _isLoading = true; // Loading flag
  String? _documentStatus; // To store document status fetched from Firestore

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch user data on screen load
  }

  // Fetch the hosting status and other data from Firestore
  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // Fetch the host status and current hosting mode from Firestore
        bool isHost = userDoc['isHost'] ?? false;
        bool isCurrentlyHosting = userDoc['isCurrentlyHosting'] ?? false;
        String documentStatus = userDoc['documentStatus'] ?? 'pending';

        // Update the AppConstants and local state
        setState(() {
          AppConstants.currentUser.isHost = isHost;
          AppConstants.currentUser.isCurrentlyHosting = isCurrentlyHosting;
          _documentStatus = documentStatus;

          // Update button text based on the fetched data
          if (isHost) {
            _hostingTitle =
                isCurrentlyHosting ? 'Guest Dashboard' : 'Host Dashboard';
          } else {
            _hostingTitle = 'List your Property';
          }

          _isLoading = false; // Data is loaded, hide the loading spinner
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch user data.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Modify hosting mode (host/guest toggle)
  modifyHostingMode() async {
    if (AppConstants.currentUser.isHost!) {
      if (AppConstants.currentUser.isCurrentlyHosting!) {
        // User is currently hosting, switch to guest mode
        setState(() {
          AppConstants.currentUser.isCurrentlyHosting = false;
          _hostingTitle = 'Host Dashboard';
        });

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'isCurrentlyHosting': false});

        Get.to(const PreGuestScreen());
      } else {
        // User is not currently hosting, switch to hosting mode
        setState(() {
          AppConstants.currentUser.isCurrentlyHosting = true;
          _hostingTitle = 'Guest Dashboard';
        });

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'isCurrentlyHosting': true});

        Get.to(PreHostScreen());
      }
    } else {
      // User is not a host, redirect to document upload page
      Get.to(() => DocumentUploadScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child:
                CircularProgressIndicator()) // Show loading spinner until data is fetched
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 50, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Center(
                      child: Column(
                        children: [
                          // Profile image button
                          MaterialButton(
                            onPressed: () {},
                            child: CircleAvatar(
                              backgroundColor: Colors.black,
                              radius: 50,
                              child: CircleAvatar(
                                backgroundImage:
                                    AppConstants.currentUser.displayImage,
                                radius: 49,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // User name and email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                AppConstants.currentUser.getFullNameOfUser(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                AppConstants.currentUser.email.toString(),
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Document Status section
                  if (_documentStatus != null &&
                      _documentStatus != 'approved') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        color: Color(0xcaf6f6f6),
                        elevation: 4,
                        shadowColor: Colors.black12,
                        child: ListTile(
                          leading:
                              Icon(Icons.edit_document, color: Colors.black),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .start, // Aligns the text to the left
                            children: [
                              Text(
                                "Host Status:",
                                style: TextStyle(color: Colors.black),
                              ),
                              SizedBox(
                                  width:
                                      10), // Optional space between the texts
                              Text(
                                "$_documentStatus",
                                style: TextStyle(color: Colors.pinkAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Horizontal card section (for uploading videos, settings, vouchers)
                  SizedBox(
                    height: 180,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (AppConstants.currentUser.isHost ?? false) ...[
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: SizedBox(
                              width: 160,
                              child: Card(
                                color: Color(0xcaf6f6f6),
                                shadowColor: Colors.black12,
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.video_collection_rounded,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Upload short videos of your listings",
                                        textAlign: TextAlign.center,
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () {
                                          Get.to(VideoUploadPage());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: Text("upload",
                                            style:
                                                TextStyle(color: Colors.black)),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(
                          width: 160,
                          child: Card(
                            color: Color(0xcaf6f6f6),
                            shadowColor: Colors.black12,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.settings_rounded,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Settings \n view more options",
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.to(SettingScreen());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: Text("enter",
                                        style: TextStyle(color: Colors.black)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Card(
                            color: Color(0xcaf6f6f6),
                            shadowColor: Colors.black12,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.free_breakfast,
                                    size: 30,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Claim one-time breakfast voucher",
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
ElevatedButton(
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("New feature on the way!"),
        duration: Duration(seconds: 2),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Text(
    "Stay Tuned",
    style: TextStyle(
      color: Colors.black,
      fontSize: 10.0,
    ),
  ),
),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Buttons section (Personal info, change hosting, FAQ, Logout)
                  ListView(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    children: [
                      // Personal Information button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Card(
                          color: Color(0xcaf6f6f6),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            leading: Icon(Icons.person_2, color: Colors.black),
                            title: Text("Personal Information",
                                style: TextStyle(color: Colors.black)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.black),
                            onTap: () {
                              Get.to(PersonDetails());
                            },
                          ),
                        ),
                      ),

                      // Change Hosting button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Card(
                          color: Color(0xcaf6f6f6),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            leading:
                                Icon(Icons.hotel_outlined, color: Colors.black),
                            title: Text(_hostingTitle,
                                style: TextStyle(color: Colors.black)),
                            trailing: Image.asset(
                              'images/images11_prev_ui.png', // Path to your asset image
                              width:
                                  44, // Set the width of the image (adjust as needed)
                              height:
                                  44, // Set the height of the image (adjust as needed)
                            ),
                            onTap: () {
                              modifyHostingMode();
                            },
                          ),
                        ),
                      ),

                      // FAQ button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Card(
                          color: Color(0xcaf6f6f6),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            leading: Icon(Icons.question_mark_rounded,
                                color: Colors.black),
                            title: Text("FAQs",
                                style: TextStyle(color: Colors.black)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.black),
                            onTap: () {
                              Get.to(FaqScreen());
                            },
                          ),
                        ),
                      ),

                      // Logout button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Card(
                          color: Color(0xcaf6f6f6),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.black),
                            title: Text("Give feedback",
                                style: TextStyle(color: Colors.black)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.black),
                            onTap: () {
                              Get.to(() => FeedbackScreen());
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
