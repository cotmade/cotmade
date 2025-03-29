import 'package:cotmade/model/booking_model.dart';
import 'package:cotmade/model/contact_model.dart';
import 'package:cotmade/model/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../global.dart';
import 'app_constants.dart';

class TripModel {
  String? id;
  String? name;
  String? type;
  double? price;
  String? description;
  String? address;
  String? city;
  String? country;
  double? rating;

  ContactModel? host;

  List<String>? imageNames;
  List<MemoryImage>? displayImages;
  List<String>? amenities;

  Map<String, int>? beds;
  Map<String, int>? bathrooms;

  List<BookingModel>? bookings;
  List<ReviewModel>? reviews;

  TripModel(
      {this.id = "",
      this.name = "",
      this.type = "",
      this.price = 0,
      this.description = "",
      this.address = "",
      this.city = "",
      this.country = "",
      this.host}) {
    displayImages = [];
    amenities = [];

    beds = {};
    bathrooms = {};
    rating = 0;

    bookings = [];
    reviews = [];
  }

  setImagesNames() {
    imageNames = [];

    for (int i = 0; i < displayImages!.length; i++) {
      imageNames!.add("image${i}.png");
    }
  }

  getPostingInfoFromFirestore() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('postings')
        .doc(AppConstants.currentUser.id)
        .collection('bookings')
        .get();

    getPostingInfoFromSnapshot(snapshot.docs.first);
  }

  getPostingInfoFromSnapshot(DocumentSnapshot snapshot) {
    address = snapshot['address'] ?? "";
    amenities = List<String>.from(snapshot['amenities']) ?? [];
    bathrooms = Map<String, int>.from(snapshot['bathrooms']) ?? {};
    beds = Map<String, int>.from(snapshot['beds']) ?? {};
    city = snapshot['city'] ?? "";
    country = snapshot['country'] ?? "";
    description = snapshot['description'] ?? "";

    String hostID = snapshot['hostID'] ?? "";
    host = ContactModel(id: hostID);

    imageNames = List<String>.from(snapshot['imageNames']) ?? [];
    name = snapshot['name'] ?? "";
    price = snapshot['price'].toDouble() ?? 0.0;
    rating = snapshot['rating'].toDouble() ?? 2.5;
    type = snapshot['type'] ?? "";
  }

  getAllImagesFromStorage() async {
    displayImages = [];

    for (int i = 0; i < imageNames!.length; i++) {
      final imageData = await FirebaseStorage.instance
          .ref()
          .child("postingImages")
          .child(id!)
          .child(imageNames![i])
          .getData(1024 * 1024);

      displayImages!.add(MemoryImage(imageData!));
    }

    return displayImages;
  }

  getFirstImageFromStorage() async {
    if (displayImages!.isNotEmpty) {
      return displayImages!.first;
    }

    final imageData = await FirebaseStorage.instance
        .ref()
        .child("postingImages")
        .child(id!)
        .child(imageNames!.first)
        .getData(1024 * 1024);

    displayImages!.add(MemoryImage(imageData!));

    return displayImages!.first;
  }

  getAmenititesString() {
    if (amenities!.isEmpty) {
      return "";
    }

    String amenitiesString = amenities.toString();

    return amenitiesString.substring(1, amenitiesString.length - 1);
  }

  double getCurrentRating() {
    if (reviews!.length == 0) {
      return 4;
    }

    double rating = 0;

    reviews!.forEach((review) {
      rating += review.rating!;
    });

    rating /= reviews!.length;

    return rating;
  }

  getHostFromFirestore() async {
    await host!.getContactInfoFromFirestore();
    await host!.getImageFromStorage();
  }

  int getGuestsNumber() {
    int? numGuests = 0;

    numGuests = numGuests + beds!['small']!;
    numGuests = numGuests + beds!['medium']! * 2;
    numGuests = numGuests + beds!['large']! * 2;

    return numGuests;
  }

  String getBedroomText() {
    String text = "";

    if (beds!["small"] != 0) {
      text = text + beds!["small"].toString() + " single/twin ";
    }

    if (beds!["medium"] != 0) {
      text = text + beds!["medium"].toString() + " double ";
    }

    if (beds!["large"] != 0) {
      text = text + this.beds!["large"].toString() + " queen/king ";
    }

    return text;
  }

  String getBathroomText() {
    String text = "";

    if (bathrooms!["full"] != 0) {
      text = text + bathrooms!["full"].toString() + " full ";
    }

    if (bathrooms!["half"] != 0) {
      text = text + bathrooms!["half"].toString() + " half ";
    }

    return text;
  }

  String getFullAddress() {
    return address! + ", " + city! + ", " + country!;
  }
}
