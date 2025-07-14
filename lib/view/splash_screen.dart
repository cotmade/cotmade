import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX for navigation
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cotmade/view/guest_home_screen.dart'; // User landing screen
import 'package:cotmade/view/unregisteredScreens/first_screen.dart'; // Login screen
import 'package:cotmade/model/app_constants.dart'; // Make sure AppConstants is imported to access user data
import 'package:cotmade/view_model/user_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cotmade/view/onboarding_screen.dart';
import 'package:cotmade/view/suspended_account_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:cotmade/api/firebase_api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait fo a brief moment before navigating
    Timer(const Duration(seconds: 3), () {
      checkAuthStatus();
    });
  }

  // Function to check authentication status
  Future<void> checkAuthStatus() async {
    // Show a circular progress indicator while loading data
    Get.dialog(
      Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible:
          false, // Prevent the dialog from being dismissed by tapping outside
    );

    // Retrieve shared preference to check if the user has seen the onboarding screen
    // Default to false if not set

    // FirebaseAuth's currentUser provides the logged-in user or null if no user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, load user data and navigate to the home screen
      String currentUserID = user.uid;
      AppConstants.currentUser.id = currentUserID;

      // Fetch user data (user info, image, and postings)
      await getUserInfoFromFirestore(currentUserID);
      if (AppConstants.currentUser.status == 0) {
        // Redirect to the "Suspended Account" screen
        Get.to(() =>
            SuspendedAccountScreen()); // Create a new screen for suspended accounts
        return; // Exit early if account is suspended
      }

      await getImageFromStorage(currentUserID);
      await AppConstants.currentUser.getMyPostingsFromFirestore();
      await FirebaseApi().uploadPendingFcmToken(currentUserID);

      // Dismiss the loading dialog after data is loaded
      Get.back(); // Close the dialog

      // Navigate to the home screen after loading data
      Get.offAll(() => VideoReelsPage());
    } else {
      // User is not logged in, navigate to the first screen (login/signup)
      Get.back(); // Close the loading dialog
      Get.offAll(() => FirstScreen());
    }
  }

  getUserInfoFromFirestore(userID) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    AppConstants.currentUser.snapshot = snapshot;
    AppConstants.currentUser.firstName = snapshot["firstName"] ?? "";
    AppConstants.currentUser.lastName = snapshot['lastName'] ?? "";
    AppConstants.currentUser.email = snapshot['email'] ?? "";
    AppConstants.currentUser.bio = snapshot['bio'] ?? "";
    AppConstants.currentUser.country = snapshot['country'] ?? "";
    AppConstants.currentUser.state = snapshot['state'] ?? "";
    AppConstants.currentUser.earnings = snapshot['earnings'].toDouble() ?? 0.0;
    AppConstants.currentUser.isHost = snapshot['isHost'] ?? false;
  }

  getImageFromStorage(userID) async {
    if (AppConstants.currentUser.displayImage != null) {
      return AppConstants.currentUser.displayImage;
    }

    final imageDataInBytes = await FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(userID)
        .child(userID + ".png")
        .getData(1024 * 1024);

    AppConstants.currentUser.displayImage = MemoryImage(imageDataInBytes!);

    return AppConstants.currentUser.displayImage;
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
        automaticallyImplyLeading: false,
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
            image: AssetImage(""), // Add your image if needed
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.2), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TweenAnimationBuilder for zooming effect
              TweenAnimationBuilder(
                tween: Tween<double>(
                    begin: 0.5,
                    end: 1.0), // Start at 50% scale and zoom to 100%
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut, // Smooth zooming curve
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale, // Apply the zoom scale
                    child: child,
                  );
                },
                child: Image.asset("images/cotmade.jpg"), // Splash logo image
              ),
              SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  "version 1.1.1", // Text on splash screen
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
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
