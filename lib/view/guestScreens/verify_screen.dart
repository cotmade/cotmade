import 'dart:io'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/account_screen.dart';

class VerifyScreen extends StatefulWidget {
  @override
  _VerifyScreenState createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Documents"), // Customize your title
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            // Navigate to AccountScreen using Get.to()
            //  Get.off(() => AccountScreen()); // Navigate to AccountScreen
            // Or you can use Get.back() to go back to the previous screen
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Center(
              child: Image.asset(
                'images/hands.jpg', // Replace with your image path
                width: 200, // Set the width (optional)
                height: 200, // Set the height (optional)
                fit:
                    BoxFit.cover, // Control how the image should fit (optional)
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Thank you!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
                "Your documents are now under review. We will get back to you shortly. \n \n For now, you can only make bookings. \n Always look out for updates on your profile"),
            SizedBox(height: 10),
            SizedBox(
              child: Card(
                color: Color(0xFFC5E1A5),
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            size: 30,
                            color: Color(0xFF689F38),
                          ),
                          SizedBox(width: 10),
                          Text("Document uploaded",
                              style: TextStyle(
                                color: Color(0xFF689F38),
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
