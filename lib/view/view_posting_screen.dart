import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/guestScreens/book_listing_screen.dart';
import 'package:cotmade/view/widgets/posting_info_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cotmade/view/guestScreens/user_profile_page.dart';

class ViewPostingScreen extends StatefulWidget {
  PostingModel? posting;

  ViewPostingScreen({
    super.key,
    this.posting,
  });

  @override
  State<ViewPostingScreen> createState() => _ViewPostingScreenState();
}

class _ViewPostingScreenState extends State<ViewPostingScreen> {
//  GoogleMapController? mapController;
//  LatLng? _center;
  // Position? _currentPosition;
  PostingModel? posting;
  bool isLoadingImages = true; // Flag to track image loading
  bool isLoadingReviews = true; // Flag to track review loading
  bool isPromoValid = false; // Flag to track promo validity
  String promoCode = ""; // Promo code string
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

  // Fetch promo code from Firestore and check validity
  Future<QuerySnapshot> fetchPromoData(postingId) async {
    return await FirebaseFirestore.instance
        .collection('promo')
        .where('postingId', isEqualTo: postingId)
        .get();
  }

  // void _onMapCreated(GoogleMapController controller) {
  //  mapController = controller;
  // }

  // _getUserLocation() async {
  //   bool serviceEnabled;
  //  LocationPermission permission;
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return;
  //  }
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.deniedForever) {
  //     return;
  //  }
  //   if (permission == LocationPermission.denied) {
  //    permission = await Geolocator.requestPermission();
  //    if (permission != LocationPermission.whileInUse &&
  //        permission != LocationPermission.always) {
  //     return;
  //   }
  //  }
  //   _currentPosition = await Geolocator.getCurrentPosition();
  //   setState(() {
  //    _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  //  });
  // }

  @override
  void initState() {
    super.initState();

    posting = widget.posting;
    getRequiredInfo();
    //   _getUserLocation();
    _getReviews(); // Fetch the reviews when the screen is initialized
  }

  // Function to format only the price (without affecting currency)
  String formatPrice(double price) {
    var formatter =
        NumberFormat('#,##0', 'en_US'); // No decimals (whole number only)
    return formatter.format(price);
  }

  // Function to copy the promo code to clipboard
  _copyToClipboard() {
    if (promoCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: promoCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code copied to clipboard')),
      );
    }
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
                              fit: BoxFit.cover,
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
                                  Get.to(BookListingScreen(
                                      posting: posting,
                                      hostID: posting!.host!.id!));
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
                                onTap: () {
                                  Get.to(() =>
                                      UserProfilePage(uid: posting!.host!.id!));
                                },
                                child: CircleAvatar(
                                  radius:
                                      MediaQuery.of(context).size.width / 12.5,
                                  backgroundColor: Colors.black,
                                  child: CircleAvatar(
                                    backgroundImage:
                                        posting!.host!.displayImage,
                                    radius:
                                        MediaQuery.of(context).size.width / 13,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  children: [
                                    //   Text(
                                    //    "Host:",
                                    //   style: const TextStyle(
                                    //     fontWeight: FontWeight.normal,
                                    //   ),
                                    // ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to host profile screen
                                        Get.to(() => UserProfilePage(
                                            uid: posting!.host!.id!));
                                      },
                                      child: Text(
                                        posting!.host!.getFullNameOfUser(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .black, // Optional: Make it look like a link
                                        ),
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
                    // Wrap this with ListView to make it scrollable
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25.0),
                      child: ListView(
                        shrinkWrap: true,
                        physics:
                            ClampingScrollPhysics(), // Ensures independent scroll
                        children: [
                          PostingInfoTileUI(
                            iconData: Icons.home,
                            category: posting!.type!,
                            categoryInfo:
                                '${posting!.getGuestsNumber()} guests',
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
                    // Promo code display
                    FutureBuilder<QuerySnapshot>(
                      future: fetchPromoData(
                          widget.posting!.id), // Fetch promo data once
                      builder: (context, promoSnapshot) {
                        if (promoSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (promoSnapshot.hasError) {
                          return Center(
                              child: Text("Error fetching promo data"));
                        }

                        if (!promoSnapshot.hasData ||
                            promoSnapshot.data!.docs.isEmpty) {
                          return SizedBox(); // No promo data for this listing
                        }

                        // Assuming there is only one promo code per listing, we access the first document
                        var promoData = promoSnapshot.data!.docs[0].data()
                            as Map<String, dynamic>;
                        String promoCode = promoData['code'] ?? '';
                        Timestamp expiryDateTimestamp =
                            promoData['expiryDate'] ?? Timestamp.now();
                        DateTime expiryDate = expiryDateTimestamp.toDate();

                        // Check if the promo code is still valid
                        bool isPromoValid = expiryDate.isAfter(DateTime.now());

                        return Center(
                          child: Column(
                            children: [
                              if (isPromoValid)
                                Row(
                                  children: [
                                    Text(
                                      'This listing is on promo: $promoCode',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors
                                            .black, // Display promo code in black
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    IconButton(
                                      icon: Icon(Icons.copy), // Copy icon
                                      onPressed: () {
                                        final textToCopy = '$promoCode';
                                        Clipboard.setData(
                                                ClipboardData(text: textToCopy))
                                            .then((_) {
                                          // Show Snackbar at the top
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Code copied to clipboard'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.only(
                                                  top: 50, left: 20, right: 20),
                                              backgroundColor: Colors.black,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                )
                              else
                                SizedBox(), // If promo is not valid, show an empty space
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 4),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to the left
                      children: [
                        Row(
                          children: [
                            Text(
                              "Caution Fee:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "${posting!.currency} ${formatPrice(posting!.caution!)}",
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: 4), // Adds spacing between the two texts
                        Text(
                          "This fee is refundable, subject to terms.",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors
                                .black, // Optional: Make it look like a footnote
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Amenities section

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to the left
                      children: [
                        Row(
                          children: [
                            // Check-In Time Label
                            Text(
                              "Check-In Time:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Check-In Time Value
                            Text(
                              "${posting!.checkInTime}",
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height:
                                16), // Add space between Check-In and Check-Out times
                        Row(
                          children: [
                            // Check-Out Time Label
                            Text(
                              "Check-Out Time:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Check-Out Time Value
                            Text(
                              "${posting!.checkOutTime}",
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 4),
                    // Amenities section
                    //
                    const Text(
                      'Amenities:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 25),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 2,
                              childAspectRatio: 3.6,
                              children: List.generate(
                                posting!.amenities!.length,
                                (index) {
                                  String currentAmenity =
                                      posting!.amenities![index];
                                  return Chip(
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0),
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
                          ],
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
                    //  _center == null
                    //      ? const Center(child: CircularProgressIndicator())
                    //      : SizedBox(
                    //          height: double.infinity,
                    //          child: GoogleMap(
                    //              onMapCreated: _onMapCreated,
                    //              initialCameraPosition: CameraPosition(
                    //               target: _center!,
                    //                zoom: 15.0,
                    //              ),
                    //              markers: {
                    //               Marker(
                    //                 markerId: const MarkerId('user_location'),
                    //                 position: _center!,
                    //                 infoWindow:
                    //                     const InfoWindow(title: 'Address'),
                    //             )
                    //           })),
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
                            : SizedBox(
                                height:
                                    100, // Set height for horizontal ListView
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: reviews.length,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final review = reviews[index];
                                    final reviewText = review['review'] ??
                                        'No review text available';
                                    final rating = review['ratings'] ?? 0;
                                    final username = review['user'] ?? 'User';

                                    return Container(
                                      width: 250, // Adjust width as needed
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Expanded(
                                            child: Text(
                                              reviewText,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$rating/5.0",
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ]),
            )
          ],
        ),
      ),
    );
  }
}
