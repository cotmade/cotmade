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
import 'package:http/http.dart' as http;
import 'package:cotmade/view/suspended_account_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:cotmade/api/firebase_api.dart';

class UserViewModel {
  RxBool isSubmitting = false.obs;
  UserModel userModel = UserModel();

  /// Generate unique referral code
  String generateReferralCode(String userId) {
    final random = Random();
    return "COT${userId.substring(0, 4)}${random.nextInt(9999).toString().padLeft(4, '0')}";
  }

  /// Sign up user
  Future<void> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
    String country,
    String state,
    String mobileNumber,
    String bio,
    File imageFileOfUser, {
    String? enteredReferralCode, // optional
  }) async {
    isSubmitting.value = true;
    Get.snackbar("Please wait", "your account is being created");

    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String currentUserID = result.user!.uid;

      // Generate unique referral code
      String myReferralCode = generateReferralCode(currentUserID);

      AppConstants.currentUser.id = currentUserID;
      AppConstants.currentUser.firstName = firstName;
      AppConstants.currentUser.lastName = lastName;
      AppConstants.currentUser.country = country;
      AppConstants.currentUser.state = state;
      AppConstants.currentUser.mobileNumber = mobileNumber;
      AppConstants.currentUser.bio = bio;
      AppConstants.currentUser.email = email;
      AppConstants.currentUser.password = password;

      // Save to Firestore
      await saveUserToFirestore(
        bio,
        mobileNumber,
        country,
        state,
        email,
        firstName,
        lastName,
        currentUserID,
        referralCode: myReferralCode,
        usedReferralCode: enteredReferralCode,
      ).whenComplete(() async {
        await addImageToFirebaseStorage(imageFileOfUser, currentUserID);
      });

      await FirebaseApi().uploadPendingFcmToken(currentUserID);

      // Send welcome email
      await sendWelcomeEmail(
          email, firstName, mobileNumber, state, country, bio);

      Get.to(VideoReelsPage());
      Get.snackbar("Congratulations", "your account has been created");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Save user in Firestore
  Future<void> saveUserToFirestore(
    bio,
    mobileNumber,
    country,
    state,
    email,
    firstName,
    lastName,
    id, {
    required String referralCode,
    String? usedReferralCode,
  }) async {
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
      "referralCode": referralCode, // ✅ always unique
    };

    if (usedReferralCode != null && usedReferralCode.isNotEmpty) {
      dataMap["usedReferralCode"] = usedReferralCode; // ✅ optional
    }

    await FirebaseFirestore.instance.collection("users").doc(id).set(dataMap);
  }

  /// Upload user image
  addImageToFirebaseStorage(File imageFileOfUser, currentUserID) async {
    Reference referenceStorage = FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(currentUserID)
        .child("$currentUserID.png");

    await referenceStorage.putFile(imageFileOfUser).whenComplete(() {});

    AppConstants.currentUser.displayImage =
        MemoryImage(imageFileOfUser.readAsBytesSync());
  }

  /// Send welcome email
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

  /// Log in user
  login(String email, String password) async {
    isSubmitting.value = true;
    Get.snackbar("Please wait", "Checking your credentials...");

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String currentUserID = result.user!.uid;
      AppConstants.currentUser.id = currentUserID;

      await getUserInfoFromFirestore(currentUserID);
      await FirebaseApi().uploadPendingFcmToken(currentUserID);

      if (AppConstants.currentUser.status == 0) {
        Get.to(() => SuspendedAccountScreen());
        return;
      }

      await getImageFromStorage(currentUserID);
      await AppConstants.currentUser.getMyPostingsFromFirestore();

      Get.snackbar("Logged-In", "You are logged in successfully.");
      Get.to(VideoReelsPage());
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e);
      Get.snackbar("Login Failed", errorMessage);
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: ${e.toString()}");
    } finally {
      isSubmitting.value = false;
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

  /// Forgot password
  forgotpassword(email) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (query.docs.isEmpty) {
      Get.snackbar("Error", "Email does not exist");
    } else {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.to(ResetPasswordScreen());
    }
  }

  /// Get user info
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

  /// Get user image
  getImageFromStorage(userID) async {
    if (AppConstants.currentUser.displayImage != null) {
      return AppConstants.currentUser.displayImage;
    }

    final imageDataInBytes = await FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(userID)
        .child("$userID.png")
        .getData(5 * 1024 * 1024);

    AppConstants.currentUser.displayImage = MemoryImage(imageDataInBytes!);

    return AppConstants.currentUser.displayImage;
  }

  /// Update balance
  updateBalance(double earnings, String userID) async {
    await userModel.updateBalance(earnings, userID);
  }

  /// Become host
  becomeHost(String userID) async {
    userModel.isHost = true;
    Map<String, dynamic> dataMap = {"isHost": true};
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .update(dataMap);
  }

  modifyCurrentlyHosting(bool isHosting) {
    userModel.isCurrentlyHosting = isHosting;
  }
}
