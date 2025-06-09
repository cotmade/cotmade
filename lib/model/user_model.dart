import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/booking_model.dart';
import 'package:cotmade/model/contact_model.dart';
import 'package:cotmade/model/conversation_model.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/model/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:uuid/uuid.dart';

class UserModel extends ContactModel {
  String? email;
  String? password;
  String? bio;
  String? mobileNumber;
  String? country;
  String? state;
  double? earnings;
  double? status;
  bool? isHost;
  bool? isCurrentlyHosting;
  DocumentSnapshot? snapshot;

  List<BookingModel>? bookings;
  List<ReviewModel>? reviews;

  List<PostingModel>? savedPostings;
  List<PostingModel>? myPostings;

  UserModel({
    String id = "",
    String firstName = "",
    String lastName = "",
    MemoryImage? displayImage,
    this.mobileNumber = "",
    this.email = "",
    this.bio = "",
    this.country = "",
    this.state = "",
  }) : super(
            id: id,
            firstName: firstName,
            lastName: lastName,
            displayImage: displayImage) {
    isHost = false;
    isCurrentlyHosting = false;

    bookings = [];
    reviews = [];

    savedPostings = [];
    myPostings = [];
  }

  createContactFromUser() {
    return ContactModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      displayImage: displayImage,
    );
  }

  Future<bool> CreatReels({
    required String video,
    required String caption,
  }) async {
    var uid = Uuid().v4();
    DateTime data = new DateTime.now();
    UserModel currentUser = UserModel();
    await FirebaseFirestore.instance.collection('reels').doc(uid).set({
      'reelsvideo': video,
      'firstName': currentUser.firstName,
      'displayImage': AppConstants.currentUser.displayImage,
      'caption': caption,
      'uid': uid,
      'postId': uid,
      'like': [],
      'time': data
    });
    return true;
  }

  addPostingToMyPostings(PostingModel posting) async {
    myPostings!.add(posting);

    List<String> myPostingIDsList = [];

    myPostings!.forEach((element) {
      myPostingIDsList.add(element.id!);
    });

    await FirebaseFirestore.instance.collection("users").doc(id).update({
      'myPostingIDs': myPostingIDsList,
    });
  }

  getMyPostingsFromFirestore() async {
    List<String> myPostingIDs =
        List<String>.from(snapshot!["myPostingIDs"]) ?? [];

    for (String postingID in myPostingIDs) {
      PostingModel posting = PostingModel(id: postingID);
      await posting.getPostingInfoFromFirestore();
      await posting.getAllBookingsFromFirestore();
      await posting.getAllImagesFromStorage();

      myPostings!.add(posting);
    }
  }

  addSavedPosting(PostingModel posting) async {
    for (var savedPosting in savedPostings!) {
      if (savedPosting.id == posting.id) {
        return;
      }
    }

    savedPostings!.add(posting);

    List<String> savedPostingIDs = [];

    savedPostings!.forEach((savedPosting) {
      savedPostingIDs.add(savedPosting.id!);
    });

    await FirebaseFirestore.instance.collection("users").doc(id).update({
      'savedPostingIDs': savedPostingIDs,
    });

    Get.snackbar("Marked as Favorite", "Saved to your Favorite List.");
  }

  removeSavedPosting(PostingModel posting) async {
    for (int i = 0; i < savedPostings!.length; i++) {
      if (savedPostings![i].id == posting.id) {
        savedPostings!.removeAt(i);
        break;
      }
    }

    List<String> savedPostingIDs = [];

    savedPostings!.forEach((savedPosting) {
      savedPostingIDs.add(savedPosting.id!);
    });

    await FirebaseFirestore.instance.collection("users").doc(id).update({
      'savedPostingIDs': savedPostingIDs,
    });

    Get.snackbar("Listing Removed", "Listing removed from your Favorite List.");
  }

  Future<void> addBookingToFirestore(
      BookingModel booking, double totalPriceForAll, String hostID) async {
    Map<String, dynamic> data = {
      'dates': booking.dates,
      'postingID': booking.posting!.id!,
    };
    await FirebaseFirestore.instance
        .doc('users/${id}/bookings/${booking.id}')
        .set(data);

    String earningsOld = "";
    await FirebaseFirestore.instance
        .collection("users")
        .doc(hostID)
        .get()
        .then((dataSnap) {
      earningsOld = dataSnap["earnings"].toString();
    });

    await FirebaseFirestore.instance.collection("users").doc(hostID).update({
      "earnings": totalPriceForAll + double.parse(earningsOld),
    });
    bookings!.add(booking);

    await addBookingConversation(booking);
  }

  addBookingConversation(BookingModel booking) async {
    ConversationModel conversation = ConversationModel();
    conversation.addConversationToFirestore(booking.posting!.host!);

    String textMessage =
        "Hi my name is ${AppConstants.currentUser!.firstName} and I have "
        "just booked ${booking.posting!.name} from ${booking.dates!.first} to "
        "${booking.dates!.last} if you have any questions contact me. Enjoy your "
        "stay!";

    await conversation.addMessageToFirestore(textMessage);
  }

  Future<void> updateBalance(double earnings, String userID) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .update({"earnings": earnings}).whenComplete(() => Get.snackbar(
              "Success", "Transaction successful.",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green,
              margin: EdgeInsets.all(8)));
    } catch (e) {
      print(e);
      Get.snackbar("Error", "Something went wrong. Please try again later.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          margin: EdgeInsets.all(8));
      print(e.toString());
      return null;
    }
  }

  List<DateTime> getAllBookedDates() {
    List<DateTime> allBookedDates = [];

    myPostings!.forEach((posting) {
      posting.bookings!.forEach((booking) {
        allBookedDates.addAll(booking.dates!);
      });
    });

    return allBookedDates;
  }
}
