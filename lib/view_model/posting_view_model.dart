import 'package:cotmade/global.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import '../model/app_constants.dart';

class PostingViewModel {
  addListingInfoToFirestore() async {
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

    DocumentReference ref =
        await FirebaseFirestore.instance.collection("postings").add(dataMap);
    postingModel.id = ref.id;

    await AppConstants.currentUser.addPostingToMyPostings(postingModel);
  }

  updatePostingInfoToFirestore() async {
    Get.snackbar("Wait", "Your listing is being updated");

    postingModel.setImagesNames();

    // Fetch the current posting document to retain old values if not provided
    DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
        .collection("postings")
        .doc(postingModel.id)
        .get();

    // Get the current values of checkInTime, checkOutTime, and caution from Firestore
    String? currentCheckInTime = postingSnapshot['checkInTime'];
    String? currentCheckOutTime = postingSnapshot['checkOutTime'];
    double? currentCaution = postingSnapshot['caution'];
    double? currentPremium = postingSnapshot['premium'];
    double? currentStatus = postingSnapshot['status'];

    // Prepare the data map for updating the posting
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

    // Update caution and premium only if the user has provided a new value, otherwise retain the old value
    if (postingModel.caution != null) {
      dataMap["caution"] = postingModel.caution;
    } else if (currentCaution != null) {
      dataMap["caution"] = currentCaution;
    }

    // Check if the user has filled in the 'caution' field during edi

    if (postingModel.checkInTime != null) {
      // If user has provided a new premium value, use it
      dataMap["checkInTime"] = postingModel.checkInTime;
    } else if (currentCheckInTime != null) {
      // If user has NOT provided a new premium value, retain the old premium value from the database
      dataMap["checkInTime"] =
          currentCheckInTime; // Use the original value from the database
    }

    if (postingModel.checkOutTime != null) {
      // If user has provided a new premium value, use it
      dataMap["checkOutTime"] = postingModel.checkOutTime;
    } else if (currentCheckOutTime != null) {
      // If user has NOT provided a new premium value, retain the old premium value from the database
      dataMap["checkOutTime"] =
          currentCheckOutTime; // Use the original value from the database
    }

    // Update Firestore with the new data
    FirebaseFirestore.instance
        .collection("postings")
        .doc(postingModel.id)
        .update(dataMap);

    // Upload new or updated images to Firebase Storage
    await addImagesToFirebaseStorage();
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
