//import 'package:nestcrib/model/posting_model.dart';
import 'package:cotmade/model/trip_model.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';

class TripsGridTileUI extends StatefulWidget {
  TripModel? posting;

  TripsGridTileUI({
    super.key,
    this.posting,
  });

  @override
  State<TripsGridTileUI> createState() => _TripsGridTileUIState();
}

class _TripsGridTileUIState extends State<TripsGridTileUI> {
  TripModel? posting;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: (posting!.displayImages!.isEmpty)
              ? Container()
              : Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: posting!.displayImages!.first,
                      fit: BoxFit.fill,
                    ),
                  ),
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
          '₦${posting!.price!} / night',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
