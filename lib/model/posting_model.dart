import 'package:cotmade/model/booking_model.dart';
import 'package:cotmade/model/contact_model.dart';
import 'package:cotmade/model/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../global.dart';
import 'app_constants.dart';

class PostingModel {
  String? id;
  String? name;
  String? type;
  double? price;
  String? description;
  String? address;
  String? city;
  String? country;
  String? currency;
  Timestamp? createdAt;
  double? caution;
  double? rating;
  double? premium;
  double? status = 1; // Set default value of status to 1
  String? checkInTime; // Add this field
  String? checkOutTime; // Add this field

  ContactModel? host;

  List<String>? imageNames;
  List<MemoryImage>? displayImages;
  List<String>? amenities;

  Map<String, int>? beds;
  Map<String, int>? bathrooms;

  List<BookingModel>? bookings;
  List<ReviewModel>? reviews;

  PostingModel(
      {this.id = "",
      this.name = "",
      this.type = "",
      this.price = 0,
      this.caution = 0,
      this.status = 1, // Set default value of status to 1
      this.description = "",
      this.address = "",
      this.city = "",
      this.country = "",
      this.createdAt, // Default timestamp value
      this.checkInTime = "", // Add this field
      this.checkOutTime = "", // Add this field
      this.currency = "",
      this.host}) {
    displayImages = [];
    amenities = [];

    beds = {};
    bathrooms = {};
    rating = 0;
    premium = 0;

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
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('postings').doc(id).get();
    if (snapshot.exists) {
      // Check if the status of the document is greater than or equal to 1
      if (snapshot['status'] >= 1) {
        // Proceed to get the posting info from the snapshot
        getPostingInfoFromSnapshot(snapshot);
      } else {
        // If the status is less than 1, show a message or handle accordingly
        Center(
          child: Text(
            'currently unavailable at the moment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        );
        // You can also show a UI message here using `setState` or other methods
      }
    } else {
      // Handle the case where the document doesn't exist
      print('Document does not exist.');
    }
  }

  getPostingInfoFromSnapshot(DocumentSnapshot snapshot) {
    id = snapshot.id;
    address = snapshot['address'] ?? "";
    amenities = List<String>.from(snapshot['amenities']) ?? [];
    bathrooms = Map<String, int>.from(snapshot['bathrooms']) ?? {};
    beds = Map<String, int>.from(snapshot['beds']) ?? {};
    city = snapshot['city'] ?? "";
    country = snapshot['country'] ?? "";
    currency = snapshot['currency'] ?? "";
    description = snapshot['description'] ?? "";

    String hostID = snapshot['hostID'] ?? "";
    host = ContactModel(id: hostID);

    imageNames = List<String>.from(snapshot['imageNames']) ?? [];
    name = snapshot['name'] ?? "";
    price = snapshot['price'].toDouble() ?? 0.0;
    caution = snapshot['caution'].toDouble() ?? 0.0;
    createdAt = snapshot['createdAt'];
    checkInTime = snapshot['checkInTime'] ?? "";
    checkOutTime = snapshot['checkOutTime'] ?? "";
    rating = snapshot['rating'].toDouble() ?? 2.5;
    premium = snapshot['premium'].toDouble() ?? 1.0;
    status = snapshot['status'].toDouble() ?? 1.0;
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

    if (bathrooms!["number"] != 0) {
      text = text + bathrooms!["number"].toString() + " full ";
    }

    if (bathrooms!["toilet"] != 0) {
      text = text + bathrooms!["toilet"].toString() + " half ";
    }

    return text;
  }

  String getFullAddress() {
    return address! + ", " + city! + ", " + country!;
  }

  getAllBookingsFromFirestore() async {
    bookings = [];

    QuerySnapshot snapshots = await FirebaseFirestore.instance
        .collection('postings')
        .doc(id)
        .collection('bookings')
        .get();

    for (var snapshot in snapshots.docs) {
      BookingModel newBooking = BookingModel();

      await newBooking.getBookingInfoFromFirestoreFromPosting(this, snapshot);

      bookings!.add(newBooking);
    }
  }

  List<DateTime> getAllBookedDates() {
    List<DateTime> dates = [];

    bookings!.forEach((booking) {
      dates.addAll(booking.dates!);
    });

    return dates;
  }

  Future<void> sendBookingPushNotification({
    required String token,
    required String userName,
    required String listingName,
  }) async {
    final String phpUrl = 'https://cotmade.com/fire/send_fcm3.php';

    final url = Uri.parse('$phpUrl?token=$token');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint('✅ Booking push notification sent');
      } else {
        debugPrint('❌ Failed to send booking push: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error calling PHP push backend: $e');
    }
  }

  Future<void> makeNewBooking(List<DateTime> dates, context, hostID) async {
    Map<String, dynamic> bookingData = {
      'dates': dates,
      'name': AppConstants.currentUser.getFullNameOfUser(),
      'userID': AppConstants.currentUser.id,
      'payment': bookingPrice,
      //  'image': displayImages!.first,
    };

    DocumentReference reference = await FirebaseFirestore.instance
        .collection('postings')
        .doc(id)
        .collection('bookings')
        .add(bookingData);

    BookingModel newBooking = BookingModel();

    newBooking.createBooking(
        this, AppConstants.currentUser.createUserFromContact(), dates);
    newBooking.id = reference.id;

    String bookingID = reference.id;
    String idd = id ?? "";
    String namee = name ?? "";
    String cityy = city ?? "";
    String countryy = country ?? "";
    String cautionn = caution.toString();
    String addresss = address ?? "";

    // Fetch host's FCM token
    try {
      final hostDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(hostID)
          .get();

      final fcmToken = hostDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await sendBookingPushNotification(
          token: fcmToken,
          userName: AppConstants.currentUser.getFullNameOfUser(),
          listingName: name ?? 'your listing',
        );
      } else {
        debugPrint('⚠️ Host FCM token not found');
      }
    } catch (e) {
      debugPrint('❌ Error fetching host FCM token or sending push: $e');
    }

    await sendWelcomeEmail(hostID, bookingID, dates, idd, cautionn, namee,
        cityy, countryy, addresss);

    bookings!.add(newBooking);
    await AppConstants.currentUser
        .addBookingToFirestore(newBooking, bookingPrice!, hostID);

    Get.snackbar("Listing", "Booked successfully.");
  }

  Future<void> sendWelcomeEmail(
      String hostID,
      String bookingID,
      List<DateTime> dates,
      String idd,
      String cautionn,
      String namee,
      String cityy,
      String countryy,
      String addresss) async {
    try {
      // Ensure the current user has an email
      String? guestEmail = AppConstants.currentUser.email;
      String? guestName = AppConstants.currentUser.getFullNameOfUser();

      if (guestEmail == null || guestEmail.isEmpty) {
        print("Guest email not found");
        return;
      }

      // Fetch the host's email from Firestore
      DocumentSnapshot hostSnapshot = await FirebaseFirestore.instance
          .collection(
              'users') // Adjust this collection to match where hosts are stored
          .doc(hostID)
          .get();

      String hostEmail = hostSnapshot['email'];

      // Convert booked dates to a comma-separated string
      String bookedDates =
          dates.map((date) => date.toIso8601String()).join(',');

      final url = Uri.parse("https://cotmade.com/app/send_email_guestbook.php");

      final response = await http.post(url, body: {
        "email": guestEmail, // Guest email
        "guest_name": guestName,
        "host_email": hostEmail, // Host email
        "booking_id": bookingID, // Booking ID from Firestore
        "booked_dates": bookedDates, // Send booked dates
        "check_in_time": checkInTime!, // Send check-in time
        "check_out_time": checkOutTime!, // Send check-out time
        "postingID": idd,
        "caution": cautionn,
        "listing": namee,
        "state": cityy,
        "country": countryy,
        "address": addresss,
      });

      if (response.statusCode == 200) {
        print("✅ Email sent successfully to guest and host");
      } else {
        print("❌ Failed to send email: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error sending email: $e");
    }
  }
}