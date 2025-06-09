import 'package:cotmade/model/posting_model.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostingSecondUI extends StatefulWidget {
  PostingModel? posting;

  PostingSecondUI({
    super.key,
    this.posting,
  });

  @override
  State<PostingSecondUI> createState() => _PostingSecondUIState();
}

class _PostingSecondUIState extends State<PostingSecondUI> {
  PostingModel? posting;

  updateUI() async {
    await posting!.getFirstImageFromStorage();

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
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
          SizedBox(
              height: 180,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                // itemBuilder: (context, index) {
                //  final card = profileCompletionCards[index];
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: SizedBox(
                        width: 300,
                        child: (posting!.displayImages!.isEmpty)
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                      image: posting!.displayImages!.first,
                                      fit: BoxFit.cover),
                                ),
                                child: Card(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  // shadowColor: Colors.grey,
                                  //  SizedBox(height: 200),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 40.0),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 15),
                                        Text(
                                          "${posting!.type} - ${posting!.city}, ${posting!.country}",
                                          maxLines: 2,
                                        ),
                                        Text(
                                          posting!.name!,
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w200),
                                        ),
                                        Text(
                                          "${posting!.currency} ${formatPrice(posting!.price!)} / night",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))),
                  ),
                ],
              ))
        ]);
  }
}
