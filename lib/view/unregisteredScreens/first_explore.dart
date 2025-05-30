import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_grid_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/unregisteredScreens/view_post_screen.dart';
import 'package:cotmade/view/widgets/posting_grid2_tile_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';

class FirstExplore extends StatefulWidget {
  const FirstExplore({super.key});

  @override
  State<FirstExplore> createState() => _FirstExploreState();
}

class _FirstExploreState extends State<FirstExplore> {
  TextEditingController controllerSearch = TextEditingController();
  TextEditingController searchController = TextEditingController();
  late Stream<List<PostingModel>> postingsStream;
  String searchType = "";
  String searchQuery = "";
  bool isNameButtonSelected = false;
  bool isCityButtonSelected = false;
  bool isTypeButtonSelected = false;

  // List of countries with their flag images
  final List<Country> countries = [
    Country('Nigeria', 'images/nig.png'),
    Country('Kenya', 'images/kenya.png'),
    Country('South Africa', 'images/South_Africa.png'),
    Country('Algeria', 'images/algeria.png'),
    Country('Angola', 'images/angola.png'),
    Country('Benin', 'images/benin.png'),
    Country('Botswana', 'images/botswana.png'),
    Country('Burkina Faso', 'images/burkina_faso.png'),
    Country('Burundi', 'images/burundi.png'),
    Country('Cape Verde', 'images/cape_verde.png'),
    Country('Cameroon', 'images/cameroon.png'),
    Country('Central African Republic', 'images/central_african_republic.png'),
    Country('Chad', 'images/chad.png'),
    Country('Comoros', 'images/comoros.png'),
    Country('Congo (Congo-Brazzaville)', 'images/congo.png'),
    Country('Congo (Democratic Republic)',
        'images/democratic_republic_of_the_congo.png'),
    Country('Djibouti', 'images/djibouti.png'),
    Country('Egypt', 'images/egypt.png'),
    Country('Equatorial Guinea', 'images/equatorial_guinea.png'),
    Country('Eritrea', 'images/eritrea.png'),
    Country('Eswatini', 'images/eswatini.png'),
    Country('Ethiopia', 'images/ethiopia.png'),
    Country('Gabon', 'images/gabon.png'),
    Country('Gambia', 'images/gambia.png'),
    Country('Ghana', 'images/ghana.png'),
    Country('Guinea', 'images/guinea.png'),
    Country('Guinea-Bissau', 'images/guinea_bissau.png'),
    Country('Ivory Coast', 'images/ivory_coast.png'),
    Country('Kenya', 'images/kenya.png'),
    Country('Lesotho', 'images/lesotho.png'),
    Country('Liberia', 'images/liberia.png'),
    Country('Libya', 'images/libya.png'),
    Country('Madagascar', 'images/madagascar.png'),
    Country('Malawi', 'images/malawi.png'),
    Country('Mali', 'images/mali.png'),
    Country('Mauritania', 'images/mauritania.png'),
    Country('Mauritius', 'images/mauritius.png'),
    Country('Morocco', 'images/morocco.png'),
    Country('Mozambique', 'images/mozambique.png'),
    Country('Namibia', 'images/namibia.png'),
    Country('Niger', 'images/niger.png'),
    Country('Rwanda', 'images/rwanda.png'),
    Country('São Tomé and Príncipe', 'images/saotome_principe.png'),
    Country('Senegal', 'images/senegal.png'),
    Country('Seychelles', 'images/seychelles.png'),
    Country('Sierra Leone', 'images/sierra_leone.png'),
    Country('Somalia', 'images/somalia.png'),
    Country('South Africa', 'images/South_Africa.png'),
    Country('South Sudan', 'images/south_sudan.png'),
    Country('Sudan', 'images/sudan.png'),
    Country('Togo', 'images/togo.png'),
    Country('Tunisia', 'images/tunisia.png'),
    Country('Uganda', 'images/uganda.png'),
    Country('Zambia', 'images/zambia.png'),
    Country('Zimbabwe', 'images/zimbabwe.png'),
  ];

  List<Country> filteredCountries = [];
  // Set the default selected country to Nigeria
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Default to Nigeria
    _selectedCountry = countries[0]; // Assuming Nigeria is the first country
    filteredCountries = countries;

    // Initial stream for fetching all postings
    postingsStream = getFilteredPostingsStream();
  }

  // Function to get the postings stream filtered by the selected country
  Stream<List<PostingModel>> getFilteredPostingsStream() {
    return FirebaseFirestore.instance
        .collection('postings')
        .where('country',
            isEqualTo: _selectedCountry!.name) // Filter by country
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        PostingModel posting = PostingModel(id: doc.id);
        posting.getPostingInfoFromSnapshot(doc);
        return posting;
      }).toList();
    });
  }

  // Method to handle search type selection and update stream
  searchByField() {
    setState(() {
      searchQuery = controllerSearch.text.trim();
    });
    postingsStream =
        getFilteredPostingsStream(); // Re-filter stream based on country and query
  }

  // Update the search type based on selected button
  pressSearchByButton(String searchTypeStr, bool isNameButtonSelectedB,
      bool isCityButtonSelectedB, bool isTypeButtonSelectedB) {
    setState(() {
      searchType = searchTypeStr;
      isNameButtonSelected = isNameButtonSelectedB;
      isCityButtonSelected = isCityButtonSelectedB;
      isTypeButtonSelected = isTypeButtonSelectedB;
    });
    searchByField(); // Re-fetch data based on selected filter
  }

  // Method to filter the listings based on search query and search type
  List<PostingModel> filterPostings(List<PostingModel> postings) {
    if (searchQuery.isEmpty) return postings; // No filter if search is empty

    String lowercasedSearchQuery =
        searchQuery.toLowerCase(); // Convert search query to lowercase

    return postings.where((posting) {
      if (searchType == "name") {
        return (posting.name?.toLowerCase().contains(lowercasedSearchQuery) ??
            false);
      } else if (searchType == "city") {
        return (posting.city?.toLowerCase().contains(lowercasedSearchQuery) ??
            false);
      } else if (searchType == "type") {
        return (posting.type?.toLowerCase().contains(lowercasedSearchQuery) ??
            false);
      }
      return false; // Default to no match for unsupported search types
    }).toList();
  }

  // Function to update the selected country and reload listings
  void _showCountryList() async {
    final Country? selected = await showDialog<Country>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select a Country"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selected: ${_selectedCountry?.name ?? "None"}'),
                  SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search for a country",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filteredCountries = countries
                            .where((country) => country.name
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    child: Column(
                      children:
                          filteredCountries.map<Widget>((Country country) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(country.imagePath),
                            radius: 15,
                          ),
                          title: Text(country.name),
                          tileColor: _selectedCountry == country
                              ? Colors.blue.shade100
                              : null, // Highlight the selected country
                          onTap: () {
                            // When a country is selected, return it
                            Navigator.pop(context, country);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // If a country was selected, update _selectedCountry
    if (selected != null) {
      setState(() {
        _selectedCountry = selected;
      });
      postingsStream =
          getFilteredPostingsStream(); // Reload stream with new country
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 20, 0),
        child: Column(
          children: [
            // Fixed section: Country selector, search bar, and search buttons
            SingleChildScrollView(
              child: Column(
                children: [
                  // Country Selector
                  GestureDetector(
                    onTap: () {
                      // Open the dialog to select a new country
                      _showCountryList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                AssetImage(_selectedCountry!.imagePath),
                            radius: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _selectedCountry!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              //  fontSize: 18,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                          ), // Dropdown arrow to indicate it's clickable
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Search Bar
                  Material(
                    elevation: 5.0,
                    color: Color(0xcaf6f6f6),
                    shadowColor: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(40),
                    child: TextField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        hintText:
                            'Where to? \nAnywhere • Any week • Add guests',
                        hintMaxLines: 2,
                        hintStyle: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      controller: controllerSearch,
                      onEditingComplete: searchByField,
                    ),
                  ),

                  // Search Buttons (Name, City, Type, Clear)
                  SizedBox(
                    height: 48,
                    width: MediaQuery.of(context).size.width / .5,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      children: [
                        MaterialButton(
                          onPressed: () {
                            pressSearchByButton("name", true, false, false);
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: isNameButtonSelected
                              ? Colors.pinkAccent
                              : Colors.white,
                          child: const Text("Name"),
                        ),
                        const SizedBox(width: 6),
                        MaterialButton(
                          onPressed: () {
                            pressSearchByButton("city", false, true, false);
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: isCityButtonSelected
                              ? Colors.pinkAccent
                              : Colors.white,
                          child: const Text("State"),
                        ),
                        const SizedBox(width: 6),
                        MaterialButton(
                          onPressed: () {
                            pressSearchByButton("type", false, false, true);
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: isTypeButtonSelected
                              ? Colors.pinkAccent
                              : Colors.white,
                          child: const Text("Type"),
                        ),
                        const SizedBox(width: 6),
                        MaterialButton(
                          onPressed: () {
                            pressSearchByButton("", false, false, false);
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: Colors.white,
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content starts here:
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Promo Section (Example for horizontal scroll)
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Top",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Add the rest of your content here (Carousels, Listings, etc.)
                    SizedBox(
                      height: 220,
                      child: StreamBuilder<List<PostingModel>>(
                        stream: postingsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            // Filter postings to include only those with premium value of 2 and status not equal to 0
                            var premiumPostings = snapshot.data!
                                .where((posting) =>
                                    posting.premium == 2.0 &&
                                    posting.status != 0.0 &&
                                    posting.status != 0.5)
                                .toList();

                            if (premiumPostings.isEmpty) {
                              return const Center(
                                child: Text('No premium listings available.'),
                              );
                            }

                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              children: premiumPostings.map((posting) {
                                return InkResponse(
                                  onTap: () {
                                    Get.to(ViewPostingScreen(posting: posting));
                                  },
                                  enableFeedback: true,
                                  child: PostingGriddTileUI(posting: posting),
                                );
                              }).toList(),
                            );
                          } else {
                            return const Center(
                              child: Text('Top listings coming soon.'),
                            );
                          }
                        },
                      ),
                    ),

                    // Carousel Section
                    const SizedBox(height: 15),
                    CarouselSlider(
                      items: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          child: Image.network(
                            'https://cotmade.com/assets/images/rb_2149143193.png',
                            fit: BoxFit.cover,
                            height: 60,
                            width: 400,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          child: Image.network(
                            'https://cotmade.com/assets/images/rb_839.png',
                            fit: BoxFit.cover,
                            height: 60,
                            width: 400,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          child: Image.network(
                            'https://cotmade.com/assets/images/rb_2149143194.png',
                            fit: BoxFit.cover,
                            height: 60,
                            width: 400,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          child: Image.network(
                            'https://cotmade.com/assets/images/rb_2149143195.png',
                            fit: BoxFit.cover,
                            height: 60,
                            width: 400,
                          ),
                        ),
                      ],
                      options: CarouselOptions(
                        height: 60.0,
                        enlargeCenterPage: true,
                        autoPlay: true,
                      ),
                    ),

                    // All Listings Section
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "All Listings",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Display Listings (GridView)
                    StreamBuilder<List<PostingModel>>(
                      stream: postingsStream,
                      builder: (context, dataSnapshots) {
                        if (dataSnapshots.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (dataSnapshots.hasData &&
                            dataSnapshots.data!.isNotEmpty) {
                          // Use all the data (no skip)
                          var listings = dataSnapshots.data!;

                          // Filter out listings where status is 0
                          var filteredListingsByStatus =
                              listings.where((posting) {
                            return posting.status != 0.0 &&
                                posting.status !=
                                    0.5; // Only include postings where status is not 0
                          }).toList();

                          if (filteredListingsByStatus.isEmpty) {
                            return const Center(
                              child: Text('No listings available.'),
                            );
                          }

                          // Prioritize listings with premium value of 2, followed by others
                          var sortedListings = filteredListingsByStatus
                            ..sort((a, b) {
                              // Handle null 'premium' values by treating null as 0 for sorting
                              double premiumA = a.premium ?? 0.0;
                              double premiumB = b.premium ?? 0.0;
                              return premiumB.compareTo(
                                  premiumA); // Sort descending (2, 1, 0)
                            });

                          // Apply search filter to the sorted listings
                          var finalFilteredListings =
                              filterPostings(sortedListings);

                          return GridView.builder(
                            physics: const ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: finalFilteredListings.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 15,
                              childAspectRatio: 3 / 4,
                            ),
                            itemBuilder: (context, index) {
                              PostingModel posting =
                                  finalFilteredListings[index];
                              return InkResponse(
                                onTap: () {
                                  Get.to(ViewPostingScreen(posting: posting));
                                },
                                enableFeedback: true,
                                child: PostingGridTileUI(posting: posting),
                              );
                            },
                          );
                        } else {
                          return const Center(
                            child: Text('Listings coming soon'),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Country {
  final String name;
  final String imagePath;

  Country(this.name, this.imagePath);
}
