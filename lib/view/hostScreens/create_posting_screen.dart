import 'dart:io';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/guest_home_screen.dart';
import 'package:cotmade/view/host_home_screen.dart';
import 'package:cotmade/view/splash_screen.dart';
import 'package:cotmade/view/widgets/amenities_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cotmade/view/hostScreens/boost_property_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/view/hostScreens/create_promo_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostingScreen extends StatefulWidget {
  PostingModel? posting;

  CreatePostingScreen({
    super.key,
    this.posting,
  });

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final formKey = GlobalKey<FormState>();
  TextEditingController _countrySearchController = TextEditingController();
  TextEditingController _nameTextEditingController = TextEditingController();
  TextEditingController _priceTextEditingController = TextEditingController();
  TextEditingController _descriptionTextEditingController =
      TextEditingController();
  TextEditingController _cautionTextEditingController = TextEditingController();
  TextEditingController _addressTextEditingController = TextEditingController();
  TextEditingController _cityTextEditingController = TextEditingController();
  TextEditingController _countryTextEditingController = TextEditingController();
  TextEditingController _amenitiesTextEditingController =
      TextEditingController();
  TextEditingController _checkInTimeController = TextEditingController();
  TextEditingController _checkOutTimeController = TextEditingController();
  double? updatedposting;
  double? updatedpostin;

  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  final List<String> residenceTypes = [
    'Detatched House',
    'Villa',
    'Apartment',
    'Condo',
    'Flat',
    'Town House',
    'Studio',
  ];
  String residenceTypeSelected = "";

  Map<String, int>? _beds;
  Map<String, int>? _bathrooms;

  List<MemoryImage>? _imagesList;
  String? selectedCurrency;
  String? selectedCountry;
  String? selectedCity;

  // Sample countries and cities for the alert box
  final Map<String, List<String>> countryCityMap = {
    'Algeria': ['Algiers', 'Oran', 'Constantine', 'Annaba', 'Blida'],
    'Angola': ['Luanda', 'Benguela', 'Cabinda', 'Huambo', 'Lubango'],
    'Benin': ['Cotonou', 'Porto-Novo', 'Djougou', 'Parakou', 'Bohicon'],
    'Botswana': [
      'Gaborone',
      'Francistown',
      'Molepolole',
      'Maun',
      'Selibe-Phikwe'
    ],
    'Burkina Faso': [
      'Ouagadougou',
      'Bobo-Dioulasso',
      'Koudougou',
      'Banfora',
      'Ouahigouya'
    ],
    'Burundi': ['Bujumbura', 'Gitega', 'Ngozi', 'Muyinga', 'Cibitoke'],
    'Cape Verde': [
      'Praia',
      'Mindelo',
      'Assomada',
      'Santa Maria',
      'São Vicente'
    ],
    'Cameroon': ['Yaoundé', 'Douala', 'Bafoussam', 'Garoua', 'Bamenda'],
    'Central African Republic': [
      'Bangui',
      'Bimbo',
      'Berbérati',
      'Carnot',
      'Mbaïki'
    ],
    'Chad': ['N’Djamena', 'Moundou', 'Sarh', 'Abéché', 'Kelo'],
    'Comoros': ['Moroni', 'Mutsamudu', 'Fomboni', 'Domoni', 'Sima'],
    'Congo (Congo-Brazzaville)': [
      'Brazzaville',
      'Pointe-Noire',
      'Dolisie',
      'Oyo',
      'Nkayi'
    ],
    'Congo (Democratic Republic)': [
      'Kinshasa',
      'Lubumbashi',
      'Mbuji-Mayi',
      'Kisangani',
      'Goma'
    ],
    'Djibouti': ['Djibouti', 'Ali Sabieh', 'Tadjourah', 'Obock', 'Arta'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza', 'Shubra El-Kheima', 'Port Said'],
    'Equatorial Guinea': ['Malabo', 'Bata', 'Ebebiyin', 'Aconibe', 'Mongomo'],
    'Eritrea': ['Asmara', 'Mendefera', 'Massawa', 'Keren', 'Dekemhare'],
    'Eswatini': ['Mbabane', 'Manzini', 'Nhlangano', 'Big Bend', 'Lobamba'],
    'Ethiopia': ['Addis Ababa', 'Mekelle', 'Dire Dawa', 'Nazret', 'Gonder'],
    'Gabon': ['Libreville', 'Port-Gentil', 'Franceville', 'Moanda', 'Oyem'],
    'Gambia': ['Banjul', 'Serekunda', 'Brikama', 'Bakau', 'Farafenni'],
    'Ghana': ['Accra', 'Kumasi', 'Tamale', 'Takoradi', 'Ashaiman'],
    'Guinea': ['Conakry', 'Kankan', 'Nzérékoré', 'Kindia', 'Faranah'],
    'Guinea-Bissau': ['Bissau', 'Bafata', 'Cacheu', 'Gabu', 'Bolama'],
    'Ivory Coast': ['Abidjan', 'Bouaké', 'San Pedro', 'Daloa', 'Yamoussoukro'],
    'Kenya': ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
    'Lesotho': [
      'Maseru',
      'Teyateyaneng',
      'Leribe',
      'Maputsoe',
      'Mohale’s Hoek'
    ],
    'Liberia': ['Monrovia', 'Gbarnga', 'Kakata', 'Buchanan', 'Harbel'],
    'Libya': ['Tripoli', 'Benghazi', 'Misrata', 'Zawiya', 'Tajoura'],
    'Madagascar': [
      'Antananarivo',
      'Toamasina',
      'Antsirabe',
      'Fianarantsoa',
      'Mahajanga'
    ],
    'Malawi': ['Lilongwe', 'Blantyre', 'Mzuzu', 'Zomba', 'Kasungu'],
    'Mali': ['Bamako', 'Ségou', 'Kayes', 'Mopti', 'Tombouctou'],
    'Mauritania': ['Nouakchott', 'Nouadhibou', 'Rosso', 'Kiffa', 'Atar'],
    'Mauritius': [
      'Port Louis',
      'Curepipe',
      'Vacoas',
      'Quatre Bornes',
      'Beau Bassin'
    ],
    'Morocco': ['Rabat', 'Casablanca', 'Marrakech', 'Fez', 'Tangier'],
    'Mozambique': ['Maputo', 'Beira', 'Nampula', 'Chimoio', 'Quelimane'],
    'Namibia': ['Windhoek', 'Swakopmund', 'Walvis Bay', 'Ondangwa', 'Rundu'],
    'Niger': ['Niamey', 'Zinder', 'Maradi', 'Agadez', 'Tahoua'],
    'Nigeria': [
      'Abia',
      'Abuja',
      'Adamawa',
      'Akwa Ibom',
      "Anambra",
      "Bauchi",
      "Bayelsa",
      "Benue",
      "Borno",
      "Cross River",
      "Delta",
      "Ebonyi",
      "Edo",
      "Ekiti",
      "Enugu",
      "Gombe",
      "Imo",
      "Jigawa",
      "Kaduna",
      "Kano",
      "Katsina",
      "Kebbi",
      "Kogi",
      "Kwara",
      "Lagos",
      "Nasarawa",
      "Niger",
      "Ogun",
      "Ondo",
      "Osun",
      "Oyo",
      "Plateau",
      "Rivers",
      "Sokoto",
      "Taraba",
      "Yobe",
      "Zamfara"
    ],
    'Rwanda': ['Kigali', 'Butare', 'Gisenyi', 'Musanze', 'Rubavu'],
    'São Tomé and Príncipe': [
      'São Tomé',
      'Neves',
      'Santana',
      'Trindade',
      'Guadalupe'
    ],
    'Senegal': ['Dakar', 'Saint-Louis', 'Thies', 'Ziguinchor', 'Kaolack'],
    'Seychelles': [
      'Victoria',
      'Anse Boileau',
      'Beau Vallon',
      'Praslin',
      'La Digue'
    ],
    'Sierra Leone': ['Freetown', 'Bo', 'Kenema', 'Makeni', 'Kailahun'],
    //'Somalia': ['Mogadishu', 'Hargeisa', 'Kismayo', 'Bosaso', 'Merca'],
    'South Africa': [
      'Johannesburg',
      'Cape Town',
      'Pretoria',
      'Durban',
      'Port Elizabeth'
    ],
    'South Sudan': ['Juba', 'Malakal', 'Wau', 'Yei', 'Aweil'],
    'Sudan': ['Khartoum', 'Omdurman', 'Port Sudan', 'Kassala', 'Nyala'],
    'Togo': ['Lomé', 'Sokodé', 'Kara', 'Atakpamé', 'Kpalimé'],
    //'Tunisia': ['Tunis', 'Sfax', 'Sousse', 'Ariana', 'Kairouan'],
    'Uganda': ['Kampala', 'Entebbe', 'Mbarara', 'Gulu', 'Jinja'],
    'Zambia': ['Lusaka', 'Kitwe', 'Ndola', 'Livingstone', 'Chingola'],
    'Zimbabwe': ['Harare', 'Bulawayo', 'Mutare', 'Gweru', 'Masvingo'],
  };

  final Map<String, String> countryCurrencyMap = {
    'Algeria': 'AED', // Algerian Dinar
    'Angola': 'USD', // Angolan Kwanza
    'Benin': 'XOF', // West African CFA Franc
    'Botswana': 'ZAR', // Botswanan Pula
    'Burkina Faso': 'XOF', // West African CFA Franc
    'Burundi': 'USD', // Burundian Franc
    'Cape Verde': 'EUR', // Cape Verdean Escudo
    'Cameroon': 'XAF', // Central African CFA Franc
    'Central African Republic': 'XAF', // Central African CFA Franc
    'Chad': 'XAF', // Central African CFA Franc
    'Comoros': 'USD', // Comorian Franc
    'Congo (Congo-Brazzaville)': 'XAF', // Congolese Franc
    'Congo (Democratic Republic)': 'USD', // Congolese Franc
    'Djibouti': 'USD', // Djiboutian Franc
    'Egypt': 'EGP', // Egyptian Pound
    'Equatorial Guinea': 'XAF', // Central African CFA Franc
    'Eritrea': 'USD', // Eritrean Nakfa
    'Eswatini': 'ZAR', // Swazi Lilangeni
    'Ethiopia': 'USD', // Ethiopian Birr
    'Gabon': 'XAF', // Central African CFA Franc
    'Gambia': 'GMD', // Gambian Dalasi
    'Ghana': 'GHS', // Ghanaian Cedi
    'Guinea': 'GNF', // Guinean Franc
    'Guinea-Bissau': 'GNF', // Guinean Franc
    'Ivory Coast': 'XOF', // West African CFA Franc
    'Kenya': 'KES', // Kenyan Shilling
    'Lesotho': 'ZAR', // Lesotho Loti
    'Liberia': 'USD', // Liberian Dollar
    'Libya': 'EGP', // Libyan Dinar
    'Madagascar': 'USD', // Malagasy Ariary
    'Malawi': 'MWK', // Malawian Kwacha
    'Mali': 'XOF', // West African CFA Franc
    'Mauritania': 'XOF', // Mauritanian Ouguiya
    'Mauritius': 'MUR', // Mauritian Rupee
    'Morocco': 'MAD', // Moroccan Dirham
    'Mozambique': 'ZAR', // Mozambican Metical
    'Namibia': 'ZAR', // Namibian Dollar
    'Niger': 'XOF', // Mauritanian Ouguiya
    'Nigeria': 'NGN', // Nigerian Naira
    'Rwanda': 'RWF', // Rwandan Franc
    'São Tomé and Príncipe': 'STD', // São Tomé and Príncipe Dobra
    'Senegal': 'XOF', // West African CFA Franc
    'Seychelles': 'USD', // Seychellois Rupee
    'Sierra Leone': 'SLL', // Sierra Leonean Leone
    //'Somalia': 'SOS', // Somali Shilling
    'South Africa': 'ZAR', // South African Rand
    'South Sudan': 'USD', // South Sudanese Pound
    'Sudan': 'USD', // Sudanese Pound
    'Togo': 'XOF', // West African CFA Franc
    //'Tunisia': 'TND', // Tunisian Dinar
    'Uganda': 'UGX', // Ugandan Shilling
    'Zambia': 'ZMW', // Zambian Kwacha
    'Zimbabwe':
        'ZAR', // Zimbabwean Dollar (Note: Zimbabwe has used multiple currencies, including the US dollar)
  };

  List<String> availableCities =
      []; // This will store cities based on selected country

  _selectImageFromGallery(int index) async {
    var imageFilePickedFromGallery =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (imageFilePickedFromGallery != null) {
      MemoryImage imageFileInBytesForm = MemoryImage(
          (File(imageFilePickedFromGallery.path)).readAsBytesSync());

      if (index < 0) {
        _imagesList!.add(imageFileInBytesForm);
      } else {
        _imagesList![index] = imageFileInBytesForm;
      }

      setState(() {});
    }
  }

  initializeValues() {
    if (widget.posting == null) {
      _nameTextEditingController = TextEditingController(text: "");
      _priceTextEditingController = TextEditingController(text: "");
      _cautionTextEditingController = TextEditingController(text: "");
      _descriptionTextEditingController = TextEditingController(text: "");
      _addressTextEditingController = TextEditingController(text: "");
      _cityTextEditingController = TextEditingController(text: "");
      _countryTextEditingController = TextEditingController(text: "");
      _amenitiesTextEditingController = TextEditingController(text: "");
      _checkInTimeController = TextEditingController(text: "");
      _checkOutTimeController = TextEditingController(text: "");
      residenceTypeSelected = residenceTypes.first;

      _beds = {'small': 0, 'medium': 0, 'large': 0};

      _bathrooms = {
        'full': 0,
        'half': 0,
      };

      _imagesList = [];
    } else {
      _nameTextEditingController =
          TextEditingController(text: widget.posting!.name);
      _priceTextEditingController =
          TextEditingController(text: widget.posting!.price.toString());
      _cautionTextEditingController =
          TextEditingController(text: widget.posting!.caution.toString());
      _descriptionTextEditingController =
          TextEditingController(text: widget.posting!.description);
      _addressTextEditingController =
          TextEditingController(text: widget.posting!.address);
      _cityTextEditingController =
          TextEditingController(text: widget.posting!.city);
      _countryTextEditingController =
          TextEditingController(text: widget.posting!.country);
      // If posting has time values as string, convert to TimeOfDay
      // Check if the time is null, and use an empty string if it is
      _checkInTimeController = TextEditingController(
          text: widget.posting!.checkInTime ??
              ""); // Default to empty string if null
      _checkOutTimeController =
          TextEditingController(text: widget.posting!.checkOutTime ?? "");
      _amenitiesTextEditingController =
          TextEditingController(text: widget.posting!.getAmenititesString());
      _beds = widget.posting!.beds;
      _bathrooms = widget.posting!.bathrooms;
      _imagesList = widget.posting!.displayImages;
      residenceTypeSelected = widget.posting!.type!;
      selectedCurrency = widget.posting!.currency;
    }

    setState(() {});
  }

  // Time selection handling
  Future<void> _selectTime(BuildContext context, String timeType) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (timeType == 'checkIn' && _checkInTime != null) {
      initialTime = _checkInTime!;
    } else if (timeType == 'checkOut' && _checkOutTime != null) {
      initialTime = _checkOutTime!;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (timeType == 'checkIn') {
          _checkInTime = picked;
          _checkInTimeController.text = _formatTime(picked);
        } else if (timeType == 'checkOut') {
          _checkOutTime = picked;
          _checkOutTimeController.text = _formatTime(picked);
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');

    return '$formattedHour:$formattedMinute $period';
  }

  @override
  void initState() {
    super.initState();
    initializeValues();
    _getEarnings();
  }

  void _getEarnings() {
    if (widget.posting != null) {
      try {
        // Listen for real-time updates for premium status, filtering where 'premium' equals 2
        FirebaseFirestore.instance
            .collection('postings')
            .doc(widget.posting!.id) // Use the `id` of the posting
            .snapshots()
            .listen((postingDocSnapshot) {
          if (postingDocSnapshot.exists) {
            // Check if 'premium' field is equal to 2
            double premiumStatus =
                postingDocSnapshot['premium']?.toDouble() ?? 0.0;

            double listStatus = postingDocSnapshot['status']?.toDouble() ?? 0.0;

            // If the premium status is 2, update the UI or trigger any logic
            if (premiumStatus == 2) {
              setState(() {
                updatedposting = premiumStatus;
              });
            }
            if (listStatus == 0) {
              setState(() {
                updatedpostin = listStatus;
              });
            }
          }
        });
      } catch (e) {
        print("Error fetching earnings: $e");
      }
    }
  }

  // Fetch Promo Code data once using Future
  Future<QuerySnapshot> fetchPromoData(postingId) async {
    return await FirebaseFirestore.instance
        .collection('promo')
        .where('postingId', isEqualTo: postingId)
        .get();
  }

  // Method to delete the image
  void _removeImage(int index) {
    setState(() {
      _imagesList!
          .removeAt(index); // Remove the image from the list at the given index
    });
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
                begin: FractionalOffset(0, 0),
                end: FractionalOffset(1, 0),
                stops: [0, 1],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
          title: const Text(
            "Create/Update a Listing",
            style: TextStyle(color: Colors.black),
          ),
          leading: Column(
            children: [
              IconButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  if (residenceTypeSelected == "") {
                    return;
                  }

                  if (_imagesList!.isEmpty) {
                    return;
                  }

                  postingModel.name = _nameTextEditingController.text;
                  postingModel.price =
                      double.parse(_priceTextEditingController.text);
                  postingModel.caution =
                      double.parse(_cautionTextEditingController.text);
                  postingModel.description =
                      _descriptionTextEditingController.text;
                  postingModel.address = _addressTextEditingController.text;
                  postingModel.city =
                      selectedCity ?? _cityTextEditingController.text;
                  postingModel.country =
                      selectedCountry ?? _countryTextEditingController.text;
                  postingModel.amenities =
                      _amenitiesTextEditingController.text.split(",");
                  postingModel.type = residenceTypeSelected;
                  postingModel.beds = _beds;
                  postingModel.bathrooms = _bathrooms;
                  postingModel.displayImages = _imagesList;
                  postingModel.currency = selectedCurrency;
                  postingModel.checkInTime =
                      _checkInTime != null ? _formatTime(_checkInTime!) : "";
                  postingModel.checkOutTime =
                      _checkOutTime != null ? _formatTime(_checkOutTime!) : "";

                  postingModel.host =
                      AppConstants.currentUser.createUserFromContact();

                  postingModel.setImagesNames();

                  // if this is new post or old post
                  if (widget.posting == null) {
                    postingModel.rating = 3.5;
                    postingModel.bookings = [];
                    postingModel.reviews = [];

                    await postingViewModel.addListingInfoToFirestore();

                    await postingViewModel.addImagesToFirebaseStorage();

                    Get.snackbar("New Listing",
                        "your new listing is uploaded successfully.");
                  } else {
                    postingModel.rating = widget.posting!.rating;
                    postingModel.bookings = widget.posting!.bookings;
                    postingModel.reviews = widget.posting!.reviews;
                    postingModel.id = widget.posting!.id;

                    for (int i = 0;
                        i < AppConstants.currentUser.myPostings!.length;
                        i++) {
                      if (AppConstants.currentUser.myPostings![i].id ==
                          postingModel.id) {
                        AppConstants.currentUser.myPostings![i] = postingModel;
                        break;
                      }
                    }

                    await postingViewModel.updatePostingInfoToFirestore();
                    await postingViewModel.addImagesToFirebaseStorage();

                    Get.snackbar(
                        "Updated", "your listing has updated successfully.");
                  }

                  // clear posting model
                  postingModel = PostingModel();

                  Get.to(HostHomeScreen());
                },
                icon: const Icon(Icons.upload, size: 20, color: Colors.black),
                tooltip: 'submit',
              ),
              Text('submit', style: TextStyle(color: Colors.black, fontSize: 8))
            ],
          )),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Boost Property Button (only for editing listings)
                      if (widget.posting != null) ...[
                        // FutureBuilder for Listing (premium status)
                        // Directly check the premium value from widget.posting

                        updatedpostin != null && updatedpostin == 0
                            ? Center(
                                child: Text('This listing is suspended.',
                                    style: TextStyle(color: Colors.red)),
                              ) // If premium equals 2
                            : Center(
                                child: Text('Active',
                                    style: TextStyle(color: Colors.black)),
                              ),
                        SizedBox(height: 5),
                        updatedposting != null && updatedposting == 2
                            ? Center(
                                child: Text('This is premium listing'),
                              ) // If premium equals 2
                            : Center(
                                //     child: MaterialButton(
                                //       onPressed: () {
                                // Your button logic here
                                //        Get.to(() => BoostPropertyPage(
                                //           postingId: widget.posting!.id ?? ''));
                                //     },
                                //      minWidth:
                                //         MediaQuery.of(context).size.width / 2,
                                //      elevation: 10,
                                //     height:
                                //         MediaQuery.of(context).size.height / 14,
                                //     color: Colors.white,
                                //     child: const Text(
                                //       'Go Premium',
                                //       style: TextStyle(
                                //           fontSize: 15, color: Colors.black),
                                //     ),
                                //   shape: RoundedRectangleBorder(
                                //     side: BorderSide(
                                //        color: Colors.black, width: 2),
                                //    borderRadius: BorderRadius.circular(5),
                                //   ),
                                //  ),
                                ),
                        SizedBox(height: 20), // Add space between streams

                        // FutureBuilder for the Promo Code
                        // FutureBuilder for the Promo Code
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

                            // Check if promo data exists
                            if (!promoSnapshot.hasData ||
                                promoSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: MaterialButton(
                                  onPressed: () {
                                    // Navigate to CreatePromoCodeScreen and pass the postingId
                                    Get.to(() => CreatePromoCodeScreen(
                                        postingId: widget.posting!.id ?? ''));
                                  },
                                  minWidth:
                                      MediaQuery.of(context).size.width / 2,
                                  elevation: 10,
                                  height:
                                      MediaQuery.of(context).size.height / 14,
                                  color: Colors.white,
                                  child: const Text(
                                    'Create Promo',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              );
                            }

                            // If promo data exists, check validity
                            var promoData = promoSnapshot.data!.docs[0].data()
                                as Map<String, dynamic>;
                            String promoCode = promoData['code'] ?? '';
                            Timestamp expiryDateTimestamp =
                                promoData['expiryDate'] ?? Timestamp.now();
                            DateTime expiryDate = expiryDateTimestamp.toDate();

                            // Check if the promo code is still valid
                            bool isPromoValid =
                                expiryDate.isAfter(DateTime.now());

                            // Show promo code if valid, else show "Create Promo" button
                            return Center(
                              child: isPromoValid
                                  ? Text(
                                      'Promo Code: $promoCode',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors
                                            .black, // Display promo code in black if valid
                                      ),
                                    )
                                  : MaterialButton(
                                      onPressed: () {
                                        // Navigate to CreatePromoCodeScreen and pass the postingId
                                        Get.to(() => CreatePromoCodeScreen(
                                            postingId:
                                                widget.posting!.id ?? ''));
                                      },
                                      minWidth:
                                          MediaQuery.of(context).size.width / 2,
                                      elevation: 10,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              14,
                                      color: Colors.white,
                                      child: const Text(
                                        'Create Promo',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.black),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],

                      //Listing name
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Listing name"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _nameTextEditingController,
                          validator: (textInput) {
                            if (textInput!.isEmpty) {
                              return "please enter a valid name";
                            }
                            return null;
                          },
                        ),
                      ),

                      //Select property type
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: DropdownButton(
                          items: residenceTypes.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (valueItem) {
                            setState(() {
                              residenceTypeSelected = valueItem.toString();
                            });
                          },
                          isExpanded: true,
                          value: residenceTypeSelected,
                          hint: const Text(
                            "Select property type",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),

                      //Description
                      Padding(
                        padding: const EdgeInsets.only(top: 21.0),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Description"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _descriptionTextEditingController,
                          maxLines: 3,
                          minLines: 1,
                          validator: (text) {
                            if (text!.isEmpty) {
                              return "please enter a valid description";
                            }
                            return null;
                          },
                        ),
                      ),

                      //Address
                      Padding(
                        padding: const EdgeInsets.only(top: 21.0),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Address"),
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _addressTextEditingController,
                          validator: (text) {
                            if (text!.isEmpty) {
                              return "please enter a valid address";
                            }
                            return null;
                          },
                        ),
                      ),

                      // Country Selector
                      // Add a TextEditingController to control the country search input

                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: GestureDetector(
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Select Country'),
                                  content: SizedBox(
                                    height: 300.0,
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: _countrySearchController,
                                          decoration: const InputDecoration(
                                              labelText: 'Search Country'),
                                          onChanged: (value) {
                                            setState(
                                                () {}); // Redraw the UI on search input change
                                          },
                                        ),
                                        Expanded(
                                          child: ListView(
                                            children: countryCityMap.keys
                                                .where((country) => country
                                                    .toLowerCase()
                                                    .contains(
                                                        _countrySearchController
                                                            .text
                                                            .toLowerCase()))
                                                .map((country) {
                                              return ListTile(
                                                title: Text(country),
                                                onTap: () {
                                                  setState(() {
                                                    selectedCountry = country;
                                                    availableCities =
                                                        countryCityMap[
                                                            country]!;
                                                    selectedCity =
                                                        availableCities.first;
                                                    selectedCurrency =
                                                        countryCurrencyMap[
                                                            country];
                                                    _countryTextEditingController
                                                        .text = country;
                                                    _cityTextEditingController
                                                        .text = selectedCity!;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _countryTextEditingController,
                              decoration:
                                  const InputDecoration(labelText: 'Country'),
                            ),
                          ),
                        ),
                      ),

                      // City Selector (based on selected country)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: DropdownButton<String>(
                          value: selectedCity,
                          isExpanded: true,
                          items: availableCities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCity = value!;
                              _cityTextEditingController.text = selectedCity!;
                            });
                          },
                          hint: Text('Select City'),
                        ),
                      ),

                      //Price / night
                      Padding(
                        padding: const EdgeInsets.only(top: 21.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Price",
                                  suffixText: selectedCurrency != null
                                      ? "$selectedCurrency / night"
                                      : '', // Concatenate currency with " / night"
                                  suffixStyle: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 25.0,
                                ),
                                keyboardType: TextInputType.number,
                                controller: _priceTextEditingController,
                                validator: (text) {
                                  if (text!.isEmpty) {
                                    return "Please enter a valid price";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      //Beds
                      const Padding(
                        padding: EdgeInsets.only(top: 30.0),
                        child: Text(
                          'Beds',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                            top: 21.0, left: 15.0, right: 15.0),
                        child: Column(
                          children: <Widget>[
                            //Twin/Single bed
                            AmenitiesUI(
                              type: 'Twin/Single',
                              startValue: _beds!['small']!,
                              decreaseValue: () {
                                _beds!['small'] = _beds!['small']! - 1;

                                if (_beds!['small']! < 0) {
                                  _beds!['small'] = 0;
                                }
                              },
                              increaseValue: () {
                                _beds!['small'] = _beds!['small']! + 1;
                              },
                            ),

                            //Double Bed
                            AmenitiesUI(
                              type: 'Double',
                              startValue: _beds!['medium']!,
                              decreaseValue: () {
                                _beds!['medium'] = _beds!['medium']! - 1;

                                if (_beds!['medium']! < 0) {
                                  _beds!['medium'] = 0;
                                }
                              },
                              increaseValue: () {
                                _beds!['medium'] = _beds!['medium']! + 1;
                              },
                            ),

                            //Queen/King bed
                            AmenitiesUI(
                              type: 'Queen/King',
                              startValue: _beds!['large']!,
                              decreaseValue: () {
                                _beds!['large'] = _beds!['large']! - 1;
                                if (_beds!['large']! < 0) {
                                  _beds!['large'] = 0;
                                }
                              },
                              increaseValue: () {
                                _beds!['large'] = _beds!['large']! + 1;
                              },
                            ),
                          ],
                        ),
                      ),

                      //Bathrooms
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Text(
                          'Bathrooms',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 25, 15, 0),
                        child: Column(
                          children: <Widget>[
                            //Full bathroom
                            AmenitiesUI(
                              type: 'Full',
                              startValue: _bathrooms!['full']!,
                              decreaseValue: () {
                                _bathrooms!['full'] = _bathrooms!['full']! - 1;

                                if (_bathrooms!['full']! < 0) {
                                  _bathrooms!['full'] = 0;
                                }
                              },
                              increaseValue: () {
                                _bathrooms!['full'] = _bathrooms!['full']! + 1;
                              },
                            ),

                            //Haldf bathroom
                            AmenitiesUI(
                              type: 'Half',
                              startValue: _bathrooms!['half']!,
                              decreaseValue: () {
                                _bathrooms!['half'] = _bathrooms!['half']! - 1;

                                if (_bathrooms!['half']! < 0) {
                                  _bathrooms!['half'] = 0;
                                }
                              },
                              increaseValue: () {
                                _bathrooms!['half'] = _bathrooms!['half']! + 1;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Check-in Time TextField
                      // Row for Check-in and Check-out Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Check-in Time
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _checkInTimeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Check-in Time',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.access_time),
                                      onPressed: () =>
                                          _selectTime(context, 'checkIn'),
                                    ),
                                  ),
                                ),
                                Text('always fill this to avoid errors',
                                    style: TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          SizedBox(width: 10), // Add space between the fields
                          // Check-out Time
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _checkOutTimeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Check-out Time',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.access_time),
                                      onPressed: () =>
                                          _selectTime(context, 'checkOut'),
                                    ),
                                  ),
                                ),
                                Text('always fill this to avoid errors',
                                    style: TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      //extra amenities
                      Padding(
                        padding: const EdgeInsets.only(top: 21.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: "Amenitites, (coma separated)"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _amenitiesTextEditingController,
                          validator: (text) {
                            if (text!.isEmpty) {
                              return "enter valid amenities & use comma to separate";
                            }
                            return null;
                          },
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),

                      //caution
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText:
                                  "Caution fee: optional. Enter 0 if none"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          keyboardType: TextInputType.number,
                          controller: _cautionTextEditingController,
                          validator: (value) {
                            // Optional field, so we don't validate it as required
                            return null; // No validation required
                          },
                        ),
                      ),

                      //photos
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 25.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: _imagesList!.length +
                              1, // Add +1 for the "add image" button
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 25,
                            childAspectRatio: 3 / 2,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _imagesList!.length) {
                              // Show the "add image" button
                              return IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _selectImageFromGallery(-1);
                                },
                              );
                            }

                            // For each image, show the image and a remove icon
                            return Stack(
                              children: [
                                MaterialButton(
                                  onPressed: () {},
                                  child: Image(
                                    image: _imagesList![index],
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon:
                                        Icon(Icons.delete, color: Colors.black),
                                    onPressed: () {
                                      _removeImage(
                                          index); // Remove the image at the given index
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
