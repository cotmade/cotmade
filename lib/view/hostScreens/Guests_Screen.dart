import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class GuestsPage extends StatefulWidget {
  final PostingModel posting;

  const GuestsPage({super.key, required this.posting});

  @override
  _GuestsPageState createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  List<Map<String, dynamic>> _guests =
      []; // List of guests and their image URLs
  Map<String, ImageProvider> _guestImages = {}; // To store images in memory

  // Fetch the guests (bookings) from the Firestore sub-collection and their images from the users collection
  void _fetchGuests() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('postings') // Assuming 'postings' is your collection
          .doc(widget.posting.id) // Assuming the posting has an 'id' field
          .collection('bookings') // Assuming 'bookings' is the sub-collection
          .get();

      List<Map<String, dynamic>> guestsList = [];

      for (var doc in querySnapshot.docs) {
        final guestData = doc.data();
        final userID = guestData['userID']; // Get the userID from the booking
        final bookingID = doc.id; // Get the booking ID

        // Fetch the user document from the 'users' collection using the userID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .get();

        final userData = userDoc.data();
        final guestName = guestData['name'];

        // Assuming you have a field 'dates' or 'startDate' in your bookings
        var dates =
            guestData['dates'] as List<dynamic>? ?? []; // Ensure it is a List

        // Filter out dates in the past and format the remaining dates
        List<String> formattedDates = [];
        DateTime now = DateTime.now();
        DateTime today =
            DateTime(now.year, now.month, now.day); // Remove time component

        if (dates.isNotEmpty) {
          for (var date in dates) {
            if (date is Timestamp) {
              DateTime dateTime = date.toDate();
              DateTime bookingDate = DateTime(
                  dateTime.year, dateTime.month, dateTime.day); // Remove time

              // Include today and future dates
              if (bookingDate.isAtSameMomentAs(today) ||
                  bookingDate.isAfter(today)) {
                formattedDates
                    .add(DateFormat('MMMM dd, yyyy').format(bookingDate));
              }
            }
          }
        }

        // Sort the dates in ascending order (by month)
        formattedDates.sort((a, b) {
          DateTime dateA = DateFormat('MMMM dd, yyyy').parse(a);
          DateTime dateB = DateFormat('MMMM dd, yyyy').parse(b);
          return dateA.compareTo(dateB); // Ascending order
        });

        // Call the getImageFromStorage method for each user
        await _getImageFromStorage(userID);

        if (formattedDates.isNotEmpty) {
          guestsList.add({
            'name': guestName,
            'userID': userID, // Store userID to later retrieve the image
            'dates': formattedDates,
            'bookingID': bookingID, // Include booking ID
          });
        }
      }

      setState(() {
        _guests = guestsList;
      });
    } catch (e) {
      print("Error fetching guests: $e");
      // Handle error appropriately
    }
  }

  // Fetch the image from Firebase Storage
  Future<void> _getImageFromStorage(String uid) async {
    try {
      final imageDataInBytes = await FirebaseStorage.instance
          .ref()
          .child("userImages")
          .child(uid)
          .child(uid + ".png")
          .getData(1024 * 1024);

      setState(() {
        _guestImages[uid] =
            MemoryImage(imageDataInBytes!); // Store the image in the map
      });
    } catch (e) {
      print("Error fetching image for $uid: $e");
      // Handle error: you can show a default image or leave it null
      setState(() {
        _guestImages[uid] =
            const AssetImage('assets/default_user_image.png'); // Default image
      });
    }
  }

  // Show the image in a larger view (Dialog)
  void _showImageDialog(String uid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image(
            image: _guestImages[uid] ??
                const AssetImage('assets/default_user_image.png'),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchGuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booked Guests')),
      body: _guests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _guests.length,
              itemBuilder: (context, index) {
                final guest = _guests[index];
                final userID = guest['userID'];
                final guestImage = _guestImages[userID];
                final guestDates = guest['dates']; // Access dates here
                final bookingID = guest['bookingID'];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pinkAccent, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: guestImage != null
                        ? GestureDetector(
                            onTap: () => _showImageDialog(
                                userID), // Image tap to show larger image
                            child: CircleAvatar(backgroundImage: guestImage),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(guest['name']),
                    subtitle: guestDates.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Booking ID: $bookingID'),
                              const SizedBox(height: 4),
                              Text('Booked Dates:'),
                              for (var date in guest['dates']) Text(date),
                            ],
                          )
                        : Text('No booked dates available'),
                  ),
                );
              },
            ),
    );
  }
}
