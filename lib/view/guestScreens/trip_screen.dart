import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:intl/intl.dart';
import 'package:cotmade/view/guestScreens/write_review_screen.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

class TripScreen extends StatelessWidget {
  Future<void> sendWelcomeEmail(String email, String fname, String bookingID,
      String paymentAmount) async {
    final url =
        Uri.parse("https://cotmade.com/app/send_email_cancelbooking.php");

    final response = await http.post(url, body: {
      "email": email,
      "fname": fname,
      "bookingID": bookingID,
      "amount": paymentAmount,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

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
                      if (bookingSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (bookingSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${bookingSnapshot.error}'));
                      }

                      if (!bookingSnapshot.hasData ||
                          bookingSnapshot.data!.docs.isEmpty) {
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

                          DateTime? firstDateTime;
                          DateTime? lastDateTime;
                          List<String> formattedDates = [];
                          if (dates.isNotEmpty) {
                            List<DateTime> parsedDates = [];
                            for (var date in dates) {
                              if (date is Timestamp) {
                                DateTime dateTime = date.toDate();
                                parsedDates.add(dateTime);
                                formattedDates.add(DateFormat('MMMM dd, yyyy')
                                    .format(dateTime));
                              }
                            }

                            if (parsedDates.isNotEmpty) {
                              firstDateTime = parsedDates.first;
                            }
                            formattedDates.sort((a, b) => a.compareTo(b));
                          }

                          // Determine if cancel button should be hidden
                          bool hideCancelButton = false;
                          if (firstDateTime != null) {
                            final now = DateTime.now();
                            final difference = firstDateTime.difference(now);
                            if (difference.inHours <= 48) {
                              hideCancelButton = true;
                            }
                          }

                          // Determine if review button should be hidden
                          bool hideReviewButton = true;
                          if (firstDateTime != null) {
                            final now = DateTime.now();
                            final difference = now
                                .difference(firstDateTime); // Fixed direction
                            if (difference.inHours >= 22) {
                              hideReviewButton = false;
                            }
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
                                  if (!hideReviewButton)
                                    ElevatedButton(
                                      onPressed: () {
                                        // Show an AlertDialog with two options: Text Review and Video Review
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Write a Review'),
                                            content: Text(
                                                'Choose the type of review you want to leave:'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Navigate to WriteReviewScreen with isVideoReview set to false
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          WriteReviewScreen(
                                                        postingID: posting.id,
                                                        isVideoReview:
                                                            false, // For text review
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text('Text Review'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  // Navigate to WriteReviewScreen with isVideoReview set to true
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          WriteReviewScreen(
                                                        postingID: posting.id,
                                                        isVideoReview:
                                                            true, // For video review
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text('Video Review'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text('Write a review'),
                                    ),

                                  Row(
                                    children: [
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
                                      SizedBox(width: 10),
                                      if (!hideCancelButton)
                                        ElevatedButton(
                                          // cancel logic here
                                          onPressed: () async {
                                            bool confirm = await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                    'Confirm Cancellation'),
                                                content: Text(
                                                    'Are you sure you want to cancel this booking?'),
                                                actions: [
                                                  TextButton(
                                                    child: Text('No'),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                  ),
                                                  TextButton(
                                                    child: Text('Yes'),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (!confirm) return;

                                            try {
                                              final FirebaseFirestore
                                                  firestore =
                                                  FirebaseFirestore.instance;
                                              final userID =
                                                  AppConstants.currentUser.id;
                                              final postingID = posting.id;

                                              final bookingDocRef = firestore
                                                  .collection('users')
                                                  .doc(userID)
                                                  .collection('bookings')
                                                  .doc(bookingID);

                                              final postingBookingRef =
                                                  firestore
                                                      .collection('postings')
                                                      .doc(postingID)
                                                      .collection('bookings')
                                                      .doc(bookingID);

                                              // Get booking details
                                              final bookingSnapshot =
                                                  await postingBookingRef.get();
                                              final bookingData =
                                                  bookingSnapshot.data();
                                              final double paymentAmount =
                                                  (bookingData?['payment'] ?? 0)
                                                      .toDouble();

                                              // Get posting and host data
                                              final postingSnapshot =
                                                  await firestore
                                                      .collection('postings')
                                                      .doc(postingID)
                                                      .get();
                                              final postingData =
                                                  postingSnapshot.data()!;
                                              final String hostID =
                                                  postingData['hostID'];
                                              final String postingCurrency =
                                                  postingData['currency'] ??
                                                      'USD';

                                              // Get user data
                                              final userSnapshot =
                                                  await firestore
                                                      .collection('users')
                                                      .doc(userID)
                                                      .get();
                                              final userData =
                                                  userSnapshot.data()!;
                                              final double userEarnings =
                                                  (userData['earnings'] ?? 0)
                                                      .toDouble();

                                              // 🌍 Convert country to currency
                                              const Map<String, String>
                                                  countryToCurrency = {
                                                'United States': 'USD',
                                                'United Kingdom': 'GBP',
                                                'Canada': 'CAD',
                                                'Germany': 'EUR',
                                                'France': 'EUR',
                                                'Australia': 'AUD',
                                                'Algeria':
                                                    'AED', // Algerian Dinar
                                                'Angola':
                                                    'USD', // Angolan Kwanza
                                                'Benin':
                                                    'XOF', // West African CFA Franc
                                                'Botswana':
                                                    'ZAR', // Botswanan Pula
                                                'Burkina Faso':
                                                    'XOF', // West African CFA Franc
                                                'Burundi':
                                                    'USD', // Burundian Franc
                                                'Cape Verde':
                                                    'EUR', // Cape Verdean Escudo
                                                'Cameroon':
                                                    'XAF', // Central African CFA Franc
                                                'Central African Republic':
                                                    'XAF', // Central African CFA Franc
                                                'Chad':
                                                    'XAF', // Central African CFA Franc
                                                'Comoros':
                                                    'USD', // Comorian Franc
                                                'Congo (Congo-Brazzaville)':
                                                    'XAF', // Congolese Franc
                                                'Congo (Democratic Republic)':
                                                    'USD', // Congolese Franc
                                                'Djibouti':
                                                    'USD', // Djiboutian Franc
                                                'Egypt':
                                                    'EGP', // Egyptian Pound
                                                'Equatorial Guinea':
                                                    'XAF', // Central African CFA Franc
                                                'Eritrea':
                                                    'USD', // Eritrean Nakfa
                                                'Eswatini':
                                                    'ZAR', // Swazi Lilangeni
                                                'Ethiopia':
                                                    'USD', // Ethiopian Birr
                                                'Gabon':
                                                    'XAF', // Central African CFA Franc
                                                'Gambia':
                                                    'GMD', // Gambian Dalasi
                                                'Ghana': 'GHS', // Ghanaian Cedi
                                                'Guinea':
                                                    'GNF', // Guinean Franc
                                                'Guinea-Bissau':
                                                    'GNF', // Guinean Franc
                                                'Ivory Coast':
                                                    'XOF', // West African CFA Franc
                                                'Kenya':
                                                    'KES', // Kenyan Shilling
                                                'Lesotho':
                                                    'ZAR', // Lesotho Loti
                                                'Liberia':
                                                    'USD', // Liberian Dollar
                                                'Libya': 'EGP', // Libyan Dinar
                                                'Madagascar':
                                                    'USD', // Malagasy Ariary
                                                'Malawi':
                                                    'MWK', // Malawian Kwacha
                                                'Mali':
                                                    'XOF', // West African CFA Franc
                                                'Mauritania':
                                                    'XOF', // Mauritanian Ouguiya
                                                'Mauritius':
                                                    'MUR', // Mauritian Rupee
                                                'Morocco':
                                                    'MAD', // Moroccan Dirham
                                                'Mozambique':
                                                    'ZAR', // Mozambican Metical
                                                'Namibia':
                                                    'ZAR', // Namibian Dollar
                                                'Niger':
                                                    'XOF', // Mauritanian Ouguiya
                                                'Nigeria':
                                                    'NGN', // Nigerian Naira
                                                'Rwanda':
                                                    'RWF', // Rwandan Franc
                                                'São Tomé and Príncipe':
                                                    'STD', // São Tomé and Príncipe Dobra
                                                'Senegal':
                                                    'XOF', // West African CFA Franc
                                                'Seychelles':
                                                    'USD', // Seychellois Rupee
                                                'Sierra Leone':
                                                    'SLL', // Sierra Leonean Leone
                                                //'Somalia': 'SOS', // Somali Shilling
                                                'South Africa':
                                                    'ZAR', // South African Rand
                                                'South Sudan':
                                                    'USD', // South Sudanese Pound
                                                'Sudan':
                                                    'USD', // Sudanese Pound
                                                'Togo':
                                                    'XOF', // West African CFA Franc
                                                //'Tunisia': 'TND', // Tunisian Dinar
                                                'Uganda':
                                                    'UGX', // Ugandan Shilling
                                                'Zambia':
                                                    'ZMW', // Zambian Kwacha
                                                'Zimbabwe': 'ZAR',
                                              };
                                              final String userCountry =
                                                  (userData['country'] ?? '');
                                              final String userCurrency =
                                                  countryToCurrency[
                                                          userCountry.trim()] ??
                                                      'USD';

                                              // Get host data
                                              final hostSnapshot =
                                                  await firestore
                                                      .collection('users')
                                                      .doc(hostID)
                                                      .get();
                                              final hostData =
                                                  hostSnapshot.data()!;
                                              final double hostEarnings =
                                                  (hostData['earnings'] ?? 0)
                                                      .toDouble();

                                              double finalAmountToAdd =
                                                  paymentAmount;

                                              // 🔁 Convert if currencies differ
                                              if (userCurrency
                                                      .trim()
                                                      .toUpperCase() !=
                                                  postingCurrency
                                                      .trim()
                                                      .toUpperCase()) {
                                                final response = await http.get(
                                                    Uri.parse(
                                                        'https://v6.exchangerate-api.com/v6/65ecc5642a4b0653f9777381/latest/$postingCurrency'));

                                                if (response.statusCode ==
                                                    200) {
                                                  final rateData = json
                                                      .decode(response.body);
                                                  final rate = rateData[
                                                          'conversion_rates']
                                                      [userCurrency];
                                                  if (rate != null) {
                                                    finalAmountToAdd =
                                                        paymentAmount * rate;
                                                  } else {
                                                    throw Exception(
                                                        'Conversion rate not found for $userCurrency');
                                                  }
                                                } else {
                                                  throw Exception(
                                                      'Currency conversion failed: ${response.body}');
                                                }
                                              } else {
                                                // ✅ Currencies match — no conversion needed
                                                finalAmountToAdd =
                                                    paymentAmount;
                                              }

                                              // 🔒 Transaction
                                              await firestore.runTransaction(
                                                  (transaction) async {
                                                // Update guest earnings
                                                transaction.update(
                                                    firestore
                                                        .collection('users')
                                                        .doc(userID),
                                                    {
                                                      'earnings': userEarnings +
                                                          finalAmountToAdd,
                                                    });

                                                // Update host earnings
                                                transaction.update(
                                                    firestore
                                                        .collection('users')
                                                        .doc(hostID),
                                                    {
                                                      'earnings': hostEarnings -
                                                          paymentAmount,
                                                    });

                                                // Delete booking entries
                                                transaction
                                                    .delete(bookingDocRef);
                                                transaction
                                                    .delete(postingBookingRef);
                                              });

                                              // Send email and show UI success
                                              await sendWelcomeEmail(
                                                AppConstants.currentUser.email
                                                    .toString(),
                                                AppConstants.currentUser
                                                    .getFullNameOfUser(),
                                                bookingID,
                                                paymentAmount.toString(),
                                              );

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Booking cancelled and payment refunded.')),
                                              );
                                            } catch (e) {
                                              print('Cancellation error: $e');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Cancellation failed. Please try again.')),
                                              );
                                            }
                                          },
                                          child: Text('Cancel Booking'),
                                        ),
                                    ],
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
