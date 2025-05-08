import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:intl/intl.dart';
import 'package:cotmade/view/guestScreens/write_review_screen.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TripScreen extends StatelessWidget {
  // Define the print function
  void _printTripDetails(
      String postingName,
      String postingType,
      String postingDescription,
      String postingAddress,
      String postingCity,
      String postingCountry,
      List<String> formattedDates) async {
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark Text in the background (using an offset copy for shadow effect)
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Center(
                    child: pw.Text(
                      "COTMADE", // App name as watermark
                      style: pw.TextStyle(
                        fontSize: 100,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF808080), // Light grey color
                      ),
                    ),
                  ),
                ),
              ),
              // Content of the PDF
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start, // Align left
                children: [
                  pw.Text('Trip Details',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.SizedBox(height: 20),
                  pw.Text('Posting Name: $postingName',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.Text('Type: $postingType',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.Text('Description: $postingDescription',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.Text('Address: $postingAddress',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.Text('City: $postingCity',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.Text('Country: $postingCountry',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  pw.SizedBox(height: 20),
                  pw.Text('Booked Dates:',
                      style: pw.TextStyle(fontSize: 20),
                      textAlign: pw.TextAlign.left), // Left aligned

                  for (var date in formattedDates)
                    pw.Text(date,
                        style: pw.TextStyle(fontSize: 20),
                        textAlign: pw.TextAlign.left), // Left aligned
                ],
              ),
            ],
          );
        },
      ),
    );

    // Print the PDF (this will send it to the printer)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(AppConstants.currentUser.id) // Get current user ID
            .collection('bookings')
            .snapshots(), // Stream for real-time bookings updates
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (bookingSnapshot.hasError) {
            return Center(child: Text('Error: ${bookingSnapshot.error}'));
          }

          if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Trips found at this time.'));
          }

          // Extract postingIDs from the bookings, including duplicates
          List<String> postingIDs = bookingSnapshot.data!.docs
              .map((doc) => doc['postingID'] as String)
              .toList();

          // If there are more than 10 IDs, Firebase only accepts 10 IDs per query
          // You need to break the postingIDs list into chunks of 10
          List<List<String>> postingIDChunks = [];
          const int maxLimit = 10;
          for (var i = 0; i < postingIDs.length; i += maxLimit) {
            postingIDChunks.add(postingIDs.sublist(
                i,
                i + maxLimit > postingIDs.length
                    ? postingIDs.length
                    : i + maxLimit));
          }

          return FutureBuilder<List<QuerySnapshot>>(
            future: _getPostingsForChunks(postingIDChunks),
            builder: (context, postingSnapshot) {
              if (postingSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (postingSnapshot.hasError) {
                return Center(child: Text('Error: ${postingSnapshot.error}'));
              }

              if (!postingSnapshot.hasData || postingSnapshot.data!.isEmpty) {
                return Center(child: Text('No trips found.'));
              }

              // Combine all the postings from chunks into one list
              List<QueryDocumentSnapshot> postings = [];
              for (var chunk in postingSnapshot.data!) {
                postings.addAll(chunk.docs);
              }

              return ListView.builder(
                itemCount: postings.length,
                itemBuilder: (context, index) {
                  var posting = postings[index];

                  return FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('postings')
      .doc(posting.id)
      .collection('bookings')
      .where('userID', isEqualTo: AppConstants.currentUser.id)
      .get(),
  builder: (context, bookingSnapshot) {
    if (bookingSnapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (bookingSnapshot.hasError) {
      return Center(child: Text('Error: ${bookingSnapshot.error}'));
    }

    if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
      return SizedBox(); // No bookings for this user under this posting
    }


                      // Process each booking for the current posting
                      List<QueryDocumentSnapshot> bookings =
                          bookingSnapshot.data!.docs;

                      return Column(
                        children: bookings.map((bookingDoc) {
                          var bookingID = bookingDoc.id; // Get the bookingID
                          var payments =
                              bookingDoc['payment'] ?? 'No payments data';
                          var dates = bookingDoc['dates'] as List<dynamic>? ??
                              []; // Ensure it is a List

                          List<String> formattedDates = [];
                          if (dates.isNotEmpty) {
                            for (var date in dates) {
                              if (date is Timestamp) {
                                DateTime dateTime = date.toDate();
                                formattedDates.add(DateFormat('MMMM dd, yyyy')
                                    .format(dateTime));
                              }
                            }

                            formattedDates.sort((a, b) => a.compareTo(b));
                          }

                          // Get the posting details
                          String postingName = posting['name'] ?? 'No Title';
                          String postingType = posting['type'] ?? 'No Type';
                          String postingDescription =
                              posting['description'] ?? 'No Description';
                          String postingAddress =
                              posting['address'] ?? 'No Address';
                          String postingCity =
                              posting['city'] ?? 'city undefined';
                          String postingCountry =
                              posting['country'] ?? 'undefined';

                          return Card(
                            color: Color(0xcaf6f6f6),
                            shadowColor: Colors.black12,
                            margin: EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postingName,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(postingType),
                                  SizedBox(height: 8),
                                  Text(postingDescription),
                                  SizedBox(height: 8),
                                  Text(postingAddress),
                                  SizedBox(height: 8),
                                  Text(postingCity),
                                  SizedBox(height: 8),
                                  Text(postingCountry),
                                  SizedBox(height: 8),
                                  // Display formatted dates for each booking
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Booking ID: $bookingID'),
                                      SizedBox(height: 10),
                                      Text('Booked Dates:'),
                                      for (var date in formattedDates)
                                        Text(date),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Pass postingID to the WriteReviewScreen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WriteReviewScreen(
                                                  postingID: posting
                                                      .id), // Pass posting ID
                                        ),
                                      );
                                    },
                                    child: Text('Write a review'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Call the print function
                                      _printTripDetails(
                                        postingName,
                                        postingType,
                                        postingDescription,
                                        postingAddress,
                                        postingCity,
                                        postingCountry,
                                        formattedDates,
                                      );
                                    },
                                    icon: Icon(Icons.print),
                                    label: Text('Print Trip'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to return a Future that fetches postings for all chunks
  Future<List<QuerySnapshot>> _getPostingsForChunks(
      List<List<String>> postingIDChunks) async {
    List<QuerySnapshot> allPostings = [];

    for (var chunk in postingIDChunks) {
      // Query the postings collection for each chunk of IDs
      var snapshot = await FirebaseFirestore.instance
          .collection('postings')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      allPostings.add(snapshot);
    }

    return allPostings;
  }
}
