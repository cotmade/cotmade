import 'package:flutter/material.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/privacy_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cotmade/view/login_screen2.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';
import 'package:cotmade/view/guestScreens/help_centre.dart';
import 'package:cotmade/view/guestScreens/terms_of_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cotmade/view/guestScreens/faq_screen.dart';
import 'package:http/http.dart' as http;
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/user_model.dart';
import 'package:cotmade/view/webview_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

Future<void> deleteUserAccount() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final userId = AppConstants.currentUser.id; // Your assigned ID
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    String firstName = AppConstants.currentUser.firstName.toString();
    AppConstants.currentUser.firstName = firstName;
    String country = AppConstants.currentUser.country.toString();
    String state = AppConstants.currentUser.state.toString();
    String mobileNumber = AppConstants.currentUser.mobileNumber.toString();
    String bio = AppConstants.currentUser.bio.toString();
    String email = AppConstants.currentUser.email.toString();

    // Delete user document from Firestore
    await userDoc.delete();
    print("User data deleted from Firestore");

    // Delete Firebase Auth account
    await sendWelcomeEmail(email, firstName, mobileNumber, state, country, bio);
    await user.delete();
    Get.snackbar(
        "Account Deleted", "Your account has been deleted successfully");
    Get.offAll(() => FirstScreen());

    // Optionally: Navigate to login or goodbye screen
    // Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    print("Error deleting user account: $e");
  }
}

Future<void> sendWelcomeEmail(String email, String firstName,
    String mobileNumber, String state, String country, String bio) async {
  final url = Uri.parse("https://cotmade.com/app/send_email_delete.php");

  final response = await http.post(url, body: {
    "email": email,
    "firstName": firstName,
    "mobileNumber": mobileNumber,
    "state": state,
    "country": country,
    "bio": bio,
  });

  if (response.statusCode == 200) {
    print("Email sent successfully");
  } else {
    print("Failed to send email: ${response.body}");
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
                    leading:
                        const Icon(Icons.support_agent, color: Colors.black),
                    title: const Text("Contact Help Centre",
                        style: TextStyle(color: Colors.black)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.black),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Contact Support"),
                          content: Text(
                            "You can reach us via:\n\n📧 Email: support@cotmade.com\n📞 Phone: +234 903 479 5131",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), // Cancel
                              child: Text("close"),
                            ),
                          ],
                        ),
                      );
                    }),
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
                    Get.to(FaqScreen());
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
                  leading: const Icon(Icons.language, color: Colors.black),
                  title: const Text("Visit CotMade Website",
                      style: TextStyle(color: Colors.black)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black),
                  onTap: () {
                    Get.to(() => WebViewScreen(
                          url:
                              "https://cotmade.com/conflict", // Or any external link
                          title: "Conflict Resolution",
                        ));
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
            Text('Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            SizedBox(height: 10),
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
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Card(
                color: Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: ListTile(
                    leading: Icon(Icons.logout_outlined, color: Colors.black),
                    title: Text("Delete Account",
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Delete Account"),
                          content: Text(
                            "Are you sure you want to permanently delete your account? This action cannot be undone.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), // Cancel
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context); // Close dialog
                                await deleteUserAccount(); // Call deletion logic
                              },
                              child: Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
