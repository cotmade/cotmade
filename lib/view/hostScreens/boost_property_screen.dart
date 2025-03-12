import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX for navigation
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cotmade/view/guest_home_screen.dart'; // User landing screen
import 'package:cotmade/view/unregisteredScreens/first_screen.dart'; // Login screen
import 'package:cotmade/model/app_constants.dart'; // Make sure AppConstants is imported to access user data
import 'package:cotmade/view_model/user_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoostPropertyPage extends StatelessWidget {
  final String postingId;

  BoostPropertyPage({required this.postingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Boost Your Property"),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Boost your listing with ID: $postingId'),
            // Add options for boost plan selection
            ElevatedButton(
              onPressed: () async {
                // Proceed with Flutterwave payment
                bool paymentSuccess = await initiateFlutterwavePayment();

                if (paymentSuccess) {
                  // Update the posting to reflect the premium status
                  await updateListingToPremium(postingId);
                  Get.snackbar(
                      "Payment Success", "Your listing is now boosted!");
                } else {
                  Get.snackbar(
                      "Payment Failed", "The payment could not be processed.");
                }
              },
              child: const Text("Select Boost Plan & Pay"),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> initiateFlutterwavePayment() async {
    // Call Flutterwave API or SDK for payment
    return true; // Simulating successful payment
  }

  Future<void> updateListingToPremium(String postingId) async {
    // Update the listing's premium status in Firestore
    final listingRef =
        FirebaseFirestore.instance.collection('listings').doc(postingId);
    await listingRef.update({
      'premium': true,
    });

    // Create a new collection with the boosted listing details
    await FirebaseFirestore.instance.collection('boosted_listings').add({
      'name': 'Example Property Name', // Fetch from the original listing
      'address': 'Example Address',
      'city': 'Example City',
      'country': 'Example Country',
      'hostID': 'hostID', // Fetch the host ID from the user model
    });
  }
}
