import 'package:flutter/material.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:intl/intl.dart';

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

  updateUI() async {
    await posting!.getFirstImageFromStorage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    updateUI();
  }

  // Function to format only the price (without affecting currency)
  String formatPrice(double price) {
    var formatter =
        NumberFormat('#,##0', 'en_US'); // No decimals (whole number only)
    return formatter.format(price);
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
        Text(
          "${posting!.currency} ${formatPrice(posting!.price!)}/night",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
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
