import 'package:flutter/material.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostingGridTileUI extends StatefulWidget {
  final PostingModel? posting;

  PostingGridTileUI({
    super.key,
    this.posting,
  });

  @override
  State<PostingGridTileUI> createState() => _PostingGridTileUIState();
}

class _PostingGridTileUIState extends State<PostingGridTileUI> {
  PostingModel? posting;
  bool isPromoValid = false;

  updateUI() async {
    await posting!.getFirstImageFromStorage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    updateUI();
    checkPromoValidity();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: posting!.displayImages!.isEmpty
              ? Container()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image with loading indicator
                    Image(
                      image: posting!.displayImages!.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child; // When the image is loaded, show the image
                        } else {
                          // Show CircularProgressIndicator while loading
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
        ),
        Text(
          "${posting!.type} - ${posting!.city}, ${posting!.country}",
          maxLines: 2,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          posting!.name!,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w200),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            "${posting!.currency} ${formatPrice(posting!.price!)}/night",
            style: TextStyle(color: Colors.black),
          ),
          SizedBox(width: 3),
          // Conditionally show "P" in a container if promo is valid
          if (isPromoValid)
            Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        Row(
          children: [
            RatingBar.readOnly(
              size: 28.0,
              maxRating: 5,
              initialRating: posting!.getCurrentRating(),
              filledIcon: Icons.star,
              emptyIcon: Icons.star_border,
              filledColor: Colors.pink,
            ),
          ],
        ),
      ],
    );
  }
}
