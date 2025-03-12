import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_grid_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/unregisteredScreens/view_post_screen.dart';
import 'package:cotmade/view/widgets/posting_grid2_tile_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_html/flutter_html.dart'; // Add flutter_html package
import 'package:cotmade/view/webview_screen.dart';

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
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();

    // Ensure countries list is not empty before selecting the first one
    if (countries.isNotEmpty) {
      _selectedCountry = countries[0]; // Default to Nigeria (first country)
      filteredCountries = countries;
    }

    // Initial stream for fetching all postings
    postingsStream = getFilteredPostingsStream();
  }

  Stream<List<PostingModel>> getFilteredPostingsStream() {
    return FirebaseFirestore.instance
        .collection('postings')
        .where('country', isEqualTo: _selectedCountry!.name)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        PostingModel posting = PostingModel(id: doc.id);
        posting.getPostingInfoFromSnapshot(doc);
        return posting;
      }).toList();
    });
  }

  searchByField() {
    setState(() {
      searchQuery = controllerSearch.text.trim();
    });
    postingsStream = getFilteredPostingsStream();
  }

  pressSearchByButton(String searchTypeStr, bool isNameButtonSelectedB,
      bool isCityButtonSelectedB, bool isTypeButtonSelectedB) {
    setState(() {
      searchType = searchTypeStr;
      isNameButtonSelected = isNameButtonSelectedB;
      isCityButtonSelected = isCityButtonSelectedB;
      isTypeButtonSelected = isTypeButtonSelectedB;
    });
    searchByField();
  }

  List<PostingModel> filterPostings(List<PostingModel> postings) {
    if (searchQuery.isEmpty) return postings;

    return postings.where((posting) {
      if (searchType == "name") {
        return posting.name?.contains(searchQuery) ?? false;
      } else if (searchType == "city") {
        return posting.city?.contains(searchQuery) ?? false;
      } else if (searchType == "type") {
        return posting.type?.contains(searchQuery) ?? false;
      }
      return false;
    }).toList();
  }

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
                              : null,
                          onTap: () {
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

    if (selected != null) {
      setState(() {
        _selectedCountry = selected;
      });
      postingsStream = getFilteredPostingsStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 20, 0),
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
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
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
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
                      hintText: 'Where to? \nAnywhere • Any week • Add guests',
                      hintMaxLines: 2,
                      hintStyle: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    controller: controllerSearch,
                    onEditingComplete: searchByField,
                  ),
                ),
                // Search Buttons
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
                        child: const Text("City"),
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
                SizedBox(
                  height: 220,
                  child: StreamBuilder<List<PostingModel>>(
                    stream: postingsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        var promoListings = snapshot.data!.take(3).toList();
                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          children: promoListings.map((posting) {
                            return InkResponse(
                              onTap: () {
                                Get.to(ViewPostScreen(posting: posting));
                              },
                              enableFeedback: true,
                              child: PostingGriddTileUI(posting: posting),
                            );
                          }).toList(),
                        );
                      } else {
                        return const Center(
                          child: Text('Top listings coming soon'),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 15),
                CarouselSlider(
                  items: [
                    GestureDetector(
                      onTap: () {
                        Get.to(HTMLScreen(url: 'https://cotmade.com/'));
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 1),
                        child: Image.network(
                          'https://cotmade.com/assets/images/rb_2149143193.png',
                          fit: BoxFit.cover,
                          height: 60,
                          width: 400,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(HTMLScreen(url: 'https://cotmade.com'));
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 1),
                        child: Image.network(
                          'https://cotmade.com/assets/images/rb_839.png',
                          fit: BoxFit.cover,
                          height: 60,
                          width: 400,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(HTMLScreen(url: 'https://cotmade.com/'));
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 1),
                        child: Image.network(
                          'https://cotmade.com/assets/images/rb_2149143193.png',
                          fit: BoxFit.cover,
                          height: 60,
                          width: 400,
                        ),
                      ),
                    ),
                  ],
                  options: CarouselOptions(
                    height: 60.0,
                    enlargeCenterPage: true,
                    autoPlay: true,
                  ),
                ),
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
                        dataSnapshots.data!.length > 3) {
                      var listings = dataSnapshots.data!.skip(3).toList();
                      var filteredListings = filterPostings(listings);

                      return GridView.builder(
                        physics: const ScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filteredListings.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 15,
                          childAspectRatio: 3 / 4,
                        ),
                        itemBuilder: (context, index) {
                          PostingModel posting = filteredListings[index];
                          return InkResponse(
                            onTap: () {
                              Get.to(ViewPostScreen(posting: posting));
                            },
                            enableFeedback: true,
                            child: PostingGridTileUI(posting: posting),
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text('Listings coming soon.'),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
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
