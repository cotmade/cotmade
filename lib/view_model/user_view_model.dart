import 'dart:io';
import 'dart:math';

import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/user_model.dart';
import 'package:cotmade/view/data/exception.dart';
import 'package:cotmade/view/firebase_exceptions.dart';
import 'package:cotmade/view/guestScreens/account_screen.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/hostScreens/withdraw_screen.dart';
import 'package:cotmade/view/resetpassword_successful.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cotmade/view/suspended_account_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';

class UserViewModel {
  UserModel userModel = UserModel();

  signUp(email, password, firstName, lastName, country, state, mobileNumber,
      bio, imageFileOfUser) async {
    //  var connectivityResult = await Connectivity().checkConnectivity();

    Get.snackbar("Please wait", "your account is being created");

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .then((result) async {
        String currentUserID = result.user!.uid;

        AppConstants.currentUser.id = currentUserID;
        AppConstants.currentUser.firstName = firstName;
        AppConstants.currentUser.lastName = lastName;
        AppConstants.currentUser.country = country;
        AppConstants.currentUser.state = state;
        AppConstants.currentUser.mobileNumber = mobileNumber;
        AppConstants.currentUser.bio = bio;
        AppConstants.currentUser.email = email;
        AppConstants.currentUser.password = password;

        await saveUserToFirestore(bio, mobileNumber, country, state, email,
                firstName, lastName, currentUserID)
            .whenComplete(() async {
          await addImageToFirebaseStorage(imageFileOfUser, currentUserID);
        });

        // Call sendWelcomeEmail after account is created
        await sendWelcomeEmail(email, firstName, mobileNumber, state, country, bio);

        Get.to(GuestHomeScreen());
        Get.snackbar("Congratulations", "your account has been created");
      });
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> saveUserToFirestore(
      bio, mobileNumber, country, state, email, firstName, lastName, id) async {
    Map<String, dynamic> dataMap = {
      "bio": bio,
      "mobileNumber": mobileNumber,
      "country": country,
      "state": state,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "isHost": false,
      "status": 1.0,
      "myPostingIDs": [],
      "savedPostingIDs": [],
      "earnings": 0,
    };

    await FirebaseFirestore.instance.collection("users").doc(id).set(dataMap);
  }

  addImageToFirebaseStorage(File imageFileOfUser, currentUserID) async {
    Reference referenceStorage = FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(currentUserID)
        .child(currentUserID + ".png");

    await referenceStorage.putFile(imageFileOfUser).whenComplete(() {});

    AppConstants.currentUser.displayImage =
        MemoryImage(imageFileOfUser.readAsBytesSync());
  }

  Future<void> sendWelcomeEmail(String email, String firstName,
      String mobileNumber, String state, String country, String bio) async {
    final url = Uri.parse("https://cotmade.com/app/send_email.php");

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

  //log in process
  login(String email, String password) async {
    Get.snackbar("Please wait", "Checking your credentials...");

    try {
      // Try signing in with Firebase
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If successful, get the current user's ID and save it to the app's constants
      String currentUserID = result.user!.uid;
      AppConstants.currentUser.id = currentUserID;

      // Fetch user data (user info, image, and postings)
      await getUserInfoFromFirestore(currentUserID);

      // Check if the user's status is 0 (suspended)
      if (AppConstants.currentUser.status == 0) {
        // Redirect to the "Suspended Account" screen
        Get.to(() =>
            SuspendedAccountScreen()); // Create a new screen for suspended accounts
        return; // Exit early if account is suspended
      }

      await getImageFromStorage(currentUserID);
      await AppConstants.currentUser.getMyPostingsFromFirestore();

      // Notify the user of a successful login
      Get.snackbar("Logged-In", "You are logged in successfully.");

      // Navigate to the home screen after login
      Get.to(VideoReelsPage());
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors specifically
      String errorMessage = _handleAuthError(e);
      Get.snackbar("Login Failed", errorMessage);
    } catch (e) {
      // Handle any other unexpected errors
      Get.snackbar("Error", "An unexpected error occurred: ${e.toString()}");
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found for that email.";
      case 'wrong-password':
        return "Incorrect password provided.";
      case 'invalid-email':
        return "The email address is badly formatted.";
      case 'user-disabled':
        return "This account has been disabled.";
      default:
        return "Invalid login credentials.";
    }
  }

  forgotpassword(email) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (query.docs.length == 0) {
      Get.snackbar("Error", "Email does not exist");
      //Go to the sign up screen
    } else {
      // Get.snackbar("Please wait", "checking your credentials....");
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.to(ResetPasswordScreen());
      //Go to the login screen
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
    AppConstants.currentUser.status = snapshot['status'].toDouble() ?? 1.0;
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

  updateBalance(double earnings, String userID) async {
    await userModel.updateBalance(earnings, userID);
  }

  becomeHost(String userID) async {
    userModel.isHost = true;

    Map<String, dynamic> dataMap = {
      "isHost": true,
    };
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .update(dataMap);
  }

  modifyCurrentlyHosting(bool isHosting) {
    userModel.isCurrentlyHosting = isHosting;
  }
}
