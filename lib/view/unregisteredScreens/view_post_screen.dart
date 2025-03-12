import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/guestScreens/book_listing_screen.dart';
import 'package:cotmade/view/widgets/posting_info_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cotmade/view/login_screen.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';
import 'package:cotmade/view/login_screen2.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewPostScreen extends StatefulWidget {
  PostingModel? posting;

  ViewPostScreen({
    super.key,
    this.posting,
  });

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;
  PostingModel? posting;
  bool isLoadingImages = true; // Flag to track image loading
  bool isLoadingReviews = true; // Flag to track review loading
  List<Map<String, dynamic>> reviews = []; // To store the reviews

  // Fetch reviews from Firestore
  _getReviews() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(posting!
              .id) // Use posting ID to fetch the reviews for the specific posting
          .get();

      if (snapshot.exists) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(snapshot['reviews'] ?? []);
          isLoadingReviews = false;
        });
      } else {
        setState(() {
          isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  getRequiredInfo() async {
    await posting!.getAllImagesFromStorage();
    await posting!.getHostFromFirestore();

    // After loading images, set the flag to false
    setState(() {
      isLoadingImages = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    });
  }

  @override
  void initState() {
    super.initState();

    posting = widget.posting;
    getRequiredInfo();
    _getUserLocation();
    _getReviews(); // Fetch the reviews when the screen is initialized
  }

  // Function to format only the price (without affecting currency)
  String formatPrice(double price) {
    var formatter =
        NumberFormat('#,##0', 'en_US'); // No decimals (whole number only)
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white,
            ],
            begin: FractionalOffset(0.0, 0.0),
            end: FractionalOffset(1.0, 0.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp,
          )),
        ),
        title: const Text(
          'Property Information',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: () async {
              await AppConstants.currentUser.addSavedPosting(posting!);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Listing images with loading indicator
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: isLoadingImages
                      ? Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          itemCount: posting!.displayImages!.length,
                          itemBuilder: (context, index) {
                            MemoryImage currentImage =
                                posting!.displayImages![index];
                            return Image(
                              image: currentImage,
                              fit: BoxFit.fill,
                            );
                          }),
                ),
              ),
            ),
            // The rest of the content (address, description, etc.)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Posting name and price, book now button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Posting name
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 1.55,
                        child: Center(
                          child: Text(
                            posting!.name!.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ),
                      // Book now button - price
                      Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black,
                                    Colors.black,
                                  ],
                                  begin: FractionalOffset(0.0, 0.0),
                                  end: FractionalOffset(1.0, 0.0),
                                  stops: [0.0, 1.0],
                                  tileMode: TileMode.clamp,
                                )),
                            child: MaterialButton(
                              onPressed: () {
                                Get.to(LoginnScreen());
                              },
                              child: const Text(
                                'Book Now',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Text(
                            "${posting!.currency} ${formatPrice(posting!.price!)}/night",
                            style: const TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Description, profile picture, and host details
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.75,
                          child: Text(
                            posting!.description!,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 5,
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: CircleAvatar(
                                radius:
                                    MediaQuery.of(context).size.width / 12.5,
                                backgroundColor: Colors.black,
                                child: CircleAvatar(
                                  backgroundImage: posting!.host!.displayImage,
                                  radius:
                                      MediaQuery.of(context).size.width / 13,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                children: [
                                  Text(
                                    "Host:",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    posting!.host!.getFullNameOfUser(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Apartments - Beds - Bathrooms info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        PostingInfoTileUI(
                          iconData: Icons.home,
                          category: posting!.type!,
                          categoryInfo: '${posting!.getGuestsNumber()} guests',
                        ),
                        PostingInfoTileUI(
                          iconData: Icons.hotel,
                          category: 'Beds',
                          categoryInfo: posting!.getBedroomText(),
                        ),
                        PostingInfoTileUI(
                          iconData: Icons.wc,
                          category: 'Bathrooms',
                          categoryInfo: posting!.getBathroomText(),
                        ),
                      ],
                    ),
                  ),
                  // Amenities section
                  const Text(
                    'Amenities:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 25),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 3.6,
                      children: List.generate(
                        posting!.amenities!.length,
                        (index) {
                          String currentAmenity = posting!.amenities![index];
                          return Chip(
                            label: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                currentAmenity,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            backgroundColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  // Location section
                  const Text(
                    'The Location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Ensures text stays aligned properly
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.black,
                          size: 19.0,
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          // Wrap Text widget with Flexible to allow line wrapping
                          child: Text(
                            posting!.getFullAddress(),
                            style: const TextStyle(
                              fontSize: 19,
                            ),
                            softWrap:
                                true, // Allows the text to wrap onto the next line
                          ),
                        ),
                      ],
                    ),
                  ),
                  _center == null
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: double.infinity,
                          child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: _center!,
                                zoom: 15.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('user_location'),
                                  position: _center!,
                                  infoWindow:
                                      const InfoWindow(title: 'Address'),
                                )
                              })),
                  SizedBox(height: 20),
                  // Reviews Section

                  // Reviews Section
                  const Text(
                    'Reviews:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
// Display reviews
                  isLoadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : reviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text('No reviews yet.'),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Column(
                                children: reviews.map((review) {
                                  // Ensure that 'review' contains the expected keys before accessing
                                  //   final userImageUrl = review['userImageUrl'] ?? ''; // Handle missing image URL
                                  final reviewText = review['review'] ??
                                      'No review text available';
                                  final rating = review['ratings'] ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(0),
                                      // Fallback for missing username
                                      subtitle: Text(reviewText),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          //  Icon(Icons.star,
                                          //       color: Colors.pinkAccent),
                                          Text('Rating:'),
                                          SizedBox(width: 5),
                                          Text('$rating/5.0'),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
