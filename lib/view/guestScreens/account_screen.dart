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
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cotmade/view/webview_screen.dart';
import 'dart:convert';
import 'package:cotmade/view_model/user_view_model.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Default button title
  String? _aliasName;
  String _hostingTitle = 'List your Property';
  bool _isLoading = true; // Loading flag
  String? _documentStatus; // To store document status fetched from Firestore

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch user data on screen load
  }

  Future<int?> fetchPointsFromMySQL() async {
    try {
      final response = await http.get(
        Uri.parse('https://cotmade.com/app/get_points.php'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['points'] as int?;
      } else {
        print('Error fetching points: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
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
        String? alias = userDoc['alias'];

        // Update the AppConstants and local state
        setState(() {
          AppConstants.currentUser.isHost = isHost;
          AppConstants.currentUser.isCurrentlyHosting = isCurrentlyHosting;
          _documentStatus = documentStatus;
          _aliasName = alias ?? '';

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
      //  Get.snackbar("Error", "Failed to fetch user data.");
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
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.black,
                                radius: 50,
                                child: CircleAvatar(
                                  backgroundImage:
                                      AppConstants.currentUser.displayImage,
                                  radius: 49,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    final pickedImage =
                                        await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 75,
                                    );
                                    if (pickedImage != null) {
                                      await UserViewModel()
                                          .addImageToFirebaseStorage(
                                        File(pickedImage.path),
                                        FirebaseAuth.instance.currentUser!.uid,
                                      );
                                      setState(() {}); // Refresh UI
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.edit,
                                        size: 16, color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
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
                              // 🔹 Alias name (editable)
                              GestureDetector(
                                onTap: () async {
                                  String? newAlias = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      TextEditingController controller =
                                          TextEditingController(
                                              text: _aliasName ?? '');
                                      return AlertDialog(
                                        title: Text("Edit Alias Name"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: "Enter alias name",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context,
                                                controller.text.trim()),
                                            child: const Text("Save"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (newAlias != null && newAlias.isNotEmpty) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                            .instance.currentUser!.uid)
                                        .update({'alias': newAlias});

                                    setState(() {
                                      _aliasName = newAlias;
                                    });
                                  }
                                },
                                child: Text(
                                  (_aliasName != null && _aliasName!.isNotEmpty)
                                      ? _aliasName!
                                      : "Add alias name",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.pinkAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              Text(
                                AppConstants.currentUser.email.toString(),
                                style: const TextStyle(fontSize: 15),
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('apps')
                                    .doc('WAsaVgCBsUmLyYz6x5kT')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return SizedBox.shrink();
                                  }

                                  final data = snapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  final bool pointFlag =
                                      data?['points'] == true;

                                  if (!pointFlag) {
                                    return SizedBox.shrink();
                                  }

                                  // pointFlag == true, now fetch points from MySQL API
                                  return FutureBuilder<int?>(
                                    future:
                                        fetchPointsFromMySQL(), // <-- your PHP API fetch function here
                                    builder: (context, futureSnapshot) {
                                      if (futureSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Text('Loading...',
                                            style: TextStyle(fontSize: 15));
                                      }
                                      if (!futureSnapshot.hasData) {
                                        return Text('Points: 0',
                                            style: TextStyle(fontSize: 15));
                                      }

                                      final points = futureSnapshot.data!;
                                      return Text('Points: $points',
                                          style: TextStyle(fontSize: 15));
                                    },
                                  );
                                },
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
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('apps')
                              .doc('dGZh6Or6jGsUmwTR7j4G') // Your document ID
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return SizedBox.shrink();

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final bool isVoucherAvailable =
                                data?['voucher'] == false;

                            return SizedBox(
                              width: 160,
                              child: Card(
                                color: const Color(0xcaf6f6f6),
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
                                          if (isVoucherAvailable) {
                                            // If voucher is active
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text("Stay tuned!"),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          } else {
                                            // Navigate to WebViewScreen
                                            Get.to(() => WebViewScreen(
                                                  url:
                                                      "https://cotmade.com/voucher?uid=${AppConstants.currentUser.id}", // your target URL
                                                  title: "Breakfast Voucher",
                                                ));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          isVoucherAvailable
                                              ? "Stay Tuned"
                                              : "Enter",
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('apps')
                              .doc('dMB1JZPopW807a9yur4A')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(); // Show nothing while loading
                            }

                            if (snapshot.hasData) {
                              final data = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              final advert = data?['advert'] ?? false;

                              if (advert == true) {
                                return SizedBox(
                                  width: 160,
                                  child: Card(
                                    color: Color(0xcaf6f6f6),
                                    shadowColor: Colors.black12,
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.campaign,
                                            size: 30,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Campaign \n view more options",
                                            textAlign: TextAlign.center,
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.to(() => WebViewScreen(
                                                    url:
                                                        "https://cotmade.com/campaign?uid=${AppConstants.currentUser.id}", // Or any external link
                                                    title: "Campaign",
                                                  ));
                                            },
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              "enter",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }

                            return SizedBox
                                .shrink(); // Hide if advert is not true or document missing
                          },
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
