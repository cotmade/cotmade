import 'package:cotmade/global.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import '../model/app_constants.dart';
import 'package:http/http.dart' as http;

class PostingViewModel {
  RxBool isSubmitting = false.obs;
  addListingInfoToFirestore() async {
    isSubmitting.value = true;
    Get.snackbar("Wait", "your listing is uploading");
    postingModel.setImagesNames();

    Map<String, dynamic> dataMap = {
      "address": postingModel.address,
      "amenities": postingModel.amenities,
      "bathrooms": postingModel.bathrooms,
      "description": postingModel.description,
      "beds": postingModel.beds,
      "city": postingModel.city,
      "country": postingModel.country,
      "currency": postingModel.currency,
      "hostID": AppConstants.currentUser.id,
      "imageNames": postingModel.imageNames,
      "name": postingModel.name,
      "price": postingModel.price,
      "caution": postingModel.caution,
      "checkInTime": postingModel.checkInTime,
      "checkOutTime": postingModel.checkOutTime,
      "createdAt": FieldValue.serverTimestamp(),
      "rating": 3.5,
      "premium": 1.0,
      "status": 1.0,
      "type": postingModel.type,
    };

    try {
      DocumentReference ref =
          await FirebaseFirestore.instance.collection("postings").add(dataMap);
      postingModel.id = ref.id;

      // Send welcome email
      await sendWelcomeEmail(
        hostID: AppConstants.currentUser.id.toString(),
        description: postingModel.description ?? '',
        address: postingModel.address ?? '',
        name: postingModel.name ?? '',
        city: postingModel.city ?? '',
        country: postingModel.country ?? '',
        postingID: postingModel.id!,
      );

      await AppConstants.currentUser.addPostingToMyPostings(postingModel);
    } catch (e) {
      Get.snackbar("Error", "Failed to add listing: ${e.toString()}");
    } finally {
      isSubmitting.value = false; // Ensure this is always reset
    }
  }

  Future<void> sendWelcomeEmail({
    required String hostID,
    required String description,
    required String address,
    required String name,
    required String city,
    required String country,
    required String postingID,
  }) async {
    final urlEndpoint =
        Uri.parse("https://cotmade.com/app/send_email_listpost.php");

    final response = await http.post(urlEndpoint, body: {
      "hostID": hostID,
      "description": description,
      "postingID": postingID,
      "address": address,
      "name": name,
      "city": city,
      "country": country,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

  updatePostingInfoToFirestore() async {
    isSubmitting.value = true;
    Get.snackbar("Wait", "Your listing is being updated");

    postingModel.setImagesNames();

    try {
      // Fetch current posting document from Firestore
      DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
          .collection("postings")
          .doc(postingModel.id)
          .get();

      // Fetch existing data to keep if not provided
      String? currentCheckInTime = postingSnapshot['checkInTime'];
      String? currentCheckOutTime = postingSnapshot['checkOutTime'];
      double? currentCaution = postingSnapshot['caution'];
      double? currentPremium = postingSnapshot['premium'];
      double? currentStatus = postingSnapshot['status'];

      // Prepare data for update
      Map<String, dynamic> dataMap = {
        "address": postingModel.address,
        "amenities": postingModel.amenities,
        "bathrooms": postingModel.bathrooms,
        "description": postingModel.description,
        "beds": postingModel.beds,
        "city": postingModel.city,
        "country": postingModel.country,
        "currency": postingModel.currency,
        "hostID": AppConstants.currentUser.id,
        "imageNames": postingModel.imageNames,
        "name": postingModel.name,
        "price": postingModel.price,
        "createdAt": FieldValue.serverTimestamp(),
        "rating": 3.5,
        "premium": currentPremium,
        "status": currentStatus,
        "type": postingModel.type,
      };

      // Send email after the update
      await sendWelcomeEmail(
        hostID: AppConstants.currentUser.id.toString(),
        description: postingModel.description ?? '',
        address: postingModel.address ?? '',
        name: postingModel.name ?? '',
        city: postingModel.city ?? '',
        country: postingModel.country ?? '',
        postingID: postingModel.id!,
      );

      // Handle caution, check-in and check-out time updates
      if (postingModel.caution != null) {
        dataMap["caution"] = postingModel.caution;
      } else if (currentCaution != null) {
        dataMap["caution"] = currentCaution;
      }

      if (postingModel.checkInTime != null) {
        dataMap["checkInTime"] = postingModel.checkInTime;
      } else if (currentCheckInTime != null) {
        dataMap["checkInTime"] = currentCheckInTime;
      }

      if (postingModel.checkOutTime != null) {
        dataMap["checkOutTime"] = postingModel.checkOutTime;
      } else if (currentCheckOutTime != null) {
        dataMap["checkOutTime"] = currentCheckOutTime;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection("postings")
          .doc(postingModel.id)
          .update(dataMap);

      // Upload images to Firebase Storage
      await addImagesToFirebaseStorage();
    } catch (e) {
      Get.snackbar("Error", "Failed to update listing: ${e.toString()}");
    } finally {
      isSubmitting.value = false; // Always reset submitting state
    }
  }

  Future<void> sendWelcomeEmaill({
    required String hostID,
    required String description,
    required String address,
    required String name,
    required String city,
    required String country,
    required String postingID,
  }) async {
    final urlEndpoint =
        Uri.parse("https://cotmade.com/app/send_email_listpost.php");

    final response = await http.post(urlEndpoint, body: {
      "hostID": hostID,
      "description": description,
      "postingID": postingID,
      "address": address,
      "name": name,
      "city": city,
      "country": country,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

  addImagesToFirebaseStorage() async {
    for (int i = 0; i < postingModel.displayImages!.length; i++) {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child("postingImages")
          .child(postingModel.id!)
          .child(postingModel.imageNames![i]);

      await ref
          .putData(postingModel.displayImages![i].bytes)
          .whenComplete(() {});
    }
  }
}
