import 'package:flutter/material.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // To access Firebase

class PostingGriddTileUI extends StatefulWidget {
  final PostingModel? posting;

  PostingGriddTileUI({
    super.key,
    this.posting,
  });

  @override
  State<PostingGriddTileUI> createState() => _PostingGriddTileUIState();
}

class _PostingGriddTileUIState extends State<PostingGriddTileUI> {
  PostingModel? posting;
  bool isPromoValid = false; // Track if promo is valid

  // Method to fetch first image from storage
  updateUI() async {
    await posting!.getFirstImageFromStorage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    updateUI(); // Update UI after initializing the posting
    checkPromoValidity(); // Check promo validity on init
  }

  // Function to format only the price (without affecting currency)
  String formatPrice(double price) {
    var formatter =
        NumberFormat('#,##0', 'en_US'); // No decimals (whole number only)
    return formatter.format(price);
  }

  // Check promo code validity
  Future<void> checkPromoValidity() async {
    try {
      // Fetch promo document for the specific posting ID
      final promoQuerySnapshot = await FirebaseFirestore.instance
          .collection('promo')
          .where('postingId', isEqualTo: posting!.id) // Filter by postingId
          .get();

      if (promoQuerySnapshot.docs.isNotEmpty) {
        final promoDoc = promoQuerySnapshot.docs.first;

        // Extract the promo data from the document
        var promoData = promoDoc.data() as Map<String, dynamic>;
        String promoCode = promoData['code'] ?? '';
        Timestamp expiryDateTimestamp =
            promoData['expiryDate'] ?? Timestamp.now();
        DateTime expiryDate = expiryDateTimestamp.toDate();

        // Check if the promo code is still valid
        bool isPromoValid = expiryDate.isAfter(
            DateTime.now().toUtc()); // Use UTC to avoid timezone issues

        // Update the UI based on promo validity
        setState(() {
          this.isPromoValid = isPromoValid;
        });

        // Optionally, you can print the promo status for debugging
        if (isPromoValid) {
          print('Promo is valid');
        } else {
          print('Promo expired');
        }
      } else {
        print('No promo found for this posting.');
        setState(() {
          this.isPromoValid = false; // No promo found, set validity to false
        });
      }
    } catch (e) {
      print('Error checking promo: $e');
      setState(() {
        this.isPromoValid = false; // If an error occurs, set validity to false
      });
    }
  }

  // Build the UI for the promo card
  Widget buildPromoCard(String image, String text) {
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 220,
        height: 400,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: posting!
                  .displayImages!.first, // Default image if none is available
              fit: BoxFit.cover,
            ),
          ),
          child: Card(
            color: Color(0x56f6f6f6),
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          //  Get.to(AddScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child:
                            Text("Live", style: TextStyle(color: Colors.black)),
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: Text(
                          '',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          // Call share functionality here
                          shareContent();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),
                  Text("${posting!.name}", textAlign: TextAlign.center),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        "${posting!.currency} ${formatPrice(posting!.price!)}/night",
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(width: 3),
                      // Conditionally show "P" in a container if promo is valid
                      if (isPromoValid)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          '',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The required build method for StatefulWidget
  @override
  Widget build(BuildContext context) {
    if (posting == null) {
      return Center(
          child:
              CircularProgressIndicator()); // Loading state if posting is not yet available
    }

    return buildPromoCard(
      posting!.name ?? "No Title", // Default text if title is null
      posting!.description ??
          "No description available", // Default text if description is null
    );
  }

  // Share function to share content
  void shareContent() {
    String title = posting!.name ?? "No Title";
    String description = posting!.description ?? "No description available";
    String price = "${posting!.currency} ${posting!.price!} / night";
    // String imageUrl = posting!.displayImages!.isNotEmpty
    //     ? posting!.displayImages!.first
    //    : ""; // Check if an image exists

    String shareText = "$title\n$description\n$price";

    // Share the content
    Share.share(shareText);
  }
}
