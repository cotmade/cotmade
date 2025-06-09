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
import 'package:flutter/material.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';

class SuspendedAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Suspended'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 20),
            Text(
              'This account has been suspended.\n\nKindly visit https://cotmade.com/conflict to appeal account suspension.',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Optionally, add any further action for the suspended user, like logging out
                FirebaseAuth.instance.signOut();
                Get.offAll(
                    FirstScreen()); // Or any screen you want the user to go after being suspended
              },
              child: Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
