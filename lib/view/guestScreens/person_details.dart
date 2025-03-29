import 'package:flutter/material.dart';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/hostScreens/withdraw_screen.dart';
import 'package:cotmade/view/video_reels_screen.dart';
import 'package:intl/intl.dart';

class PersonDetails extends StatefulWidget {
  const PersonDetails({Key? key}) : super(key: key);

  @override
  State<PersonDetails> createState() => _PersonDetailsState();
}

class _PersonDetailsState extends State<PersonDetails> {
  final _accountNumberController = TextEditingController();
  String? _selectedBank;
  bool _isSaveButtonEnabled = false;
  String? savedBankName;
  String? savedAccountNumber;
  double? updatedEarnings;
  bool isHost = true;

  // List of banks (this can be extended or fetched from an API)
  final List<String> _banks = [
    'ABSA Bank',
    'Access Bank',
    'Al-Baraka Bank Sudan',
    'Attijariwafa Bank',
    'Awash International Bank',
    'Banco Angolano de Investimentos (BAI)',
    'Banco de Fomento Angola (BFA)',
    'Banco Nacional de Angola (BNA)',
    'Banco Comercial e de Investimentos (BCI)',
    'Banco de la République du Burundi (BRB)',
    'Banco de Moçambique (Central Bank)',
    'Banco Misr',
    'Banco Populaire du Maroc',
    'Barclays Bank Botswana (Now Absa Bank)',
    'Barclays Bank Ghana (now Absa Bank)',
    'Barclays Bank Mauritius (Now Absa Bank)',
    'Barclays Zambia (Now Absa Bank)',
    'Bank Gaborone',
    'Bank of Abyssinia',
    'Bank of Khartoum',
    'Bank Windhoek',
    'Banque Algerienne de Développement (BADR)',
    'Banque de Madagascar',
    'Banque de la République du Burundi (BRB)',
    'Banque Internationale Arabe de Tunisie (BIAT)',
    'Banque Malgache de l\'Océan Indien (BMOI)',
    'Banque Marocaine du Commerce Extérieur (BMCE)',
    'Banque Misr',
    'Banque Nationale Agricole (BNA)',
    'Banque Nationale d\'Algérie (BNA)',
    'Banque Populaire du Burundi (BPB)',
    'Banque Populaire du Maroc',
    'Banco Nacional de Angola (BNA)',
    'Banco Comercial e de Investimentos (BCI)',
    'Capitec Bank',
    'CBZ Bank',
    'Centenary Bank',
    'Commercial Bank of Ethiopia (CBE)',
    'Commercial International Bank (CIB)',
    'Co-operative Bank of Kenya',
    'CRDB Bank',
    'Dashen Bank',
    'dfcu Bank',
    'Ecobank Ghana',
    'Ecobank Zimbabwe',
    'Equity Bank Kenya',
    'First Bank',
    'First Bank of Nigeria',
    'First Capital Bank',
    'First National Bank (FNB)',
    'First National Bank Lesotho',
    'First National Bank Namibia',
    'FNB Zambia',
    'Fidelity Bank',
    'Ghana Commercial Bank (GCB)',
    'Guaranty Trust Bank (GTBank)',
    'Khartoum Bank',
    'Kenya Commercial Bank (KCB)',
    'Lesotho PostBank',
    'Millennium BCP',
    'National Bank of Egypt (NBE)',
    'National Bank of Commerce (NBC)',
    'Nedbank',
    'Nedbank Namibia',
    'NMB Bank',
    'Standard Bank',
    'Standard Bank Mozambique',
    'Standard Bank Namibia',
    'Standard Bank South Africa',
    'Standard Chartered Bank Botswana',
    'Standard Chartered Bank Ghana',
    'Standard Chartered Bank Kenya',
    'Standard Chartered Bank Tanzania',
    'Standard Chartered Bank Zambia',
    'Standard Chartered Bank Zimbabwe',
    'Stanbic Bank',
    'Stanbic Bank Uganda',
    'Sterling Bank',
    'Sudanese Commercial Bank',
    'Société Tunisienne de Banque (STB)',
    'United Bank for Africa (UBA)',
    'Zenith Bank',
    'Zambia National Commercial Bank (ZANACO)',
  ];

  @override
  void initState() {
    super.initState();
    _getBankDetails();
    _getEarnings(); // Listen for earnings separately
  }

  // Function to get the bank details and earnings from Firebase
  void _getBankDetails() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Listen for real-time updates
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDocSnapshot) {
          if (userDocSnapshot.exists) {
            setState(() {
              savedBankName = userDocSnapshot['bankName'];
              savedAccountNumber = userDocSnapshot['accountNumber'];
              // updatedEarnings =
              //    userDocSnapshot['earnings']; // Fetch earnings as well
            });
          }
        });
      } catch (e) {
        print("Error fetching bank details or earnings: $e");
      }
    }
  }

  void _getEarnings() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Listen for real-time updates for earnings
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDocSnapshot) {
          if (userDocSnapshot.exists) {
            setState(() {
              updatedEarnings = userDocSnapshot['earnings']?.toDouble() ?? 0.0;
            });
          }
        });
      } catch (e) {
        print("Error fetching earnings: $e");
      }
    }
  }

// Function to show the dialog to input bank details
  void _showBankDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  Colors.white, // Ensure the background color is white
              title: Text(
                'Enter Bank Details',
                style: TextStyle(color: Colors.black),
              ), // Title style
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TextField for account number
                  TextField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      labelStyle:
                          TextStyle(color: Colors.black), // Label text color
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.black), // Border color when focused
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateSaveButtonState(); // Update save button state when account number changes
                    },
                  ),
                  SizedBox(height: 10),
                  // Searchable bank dropdown using Autocomplete
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return _banks
                          .where((bank) => bank
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (selected) {
                      setState(() {
                        _selectedBank = selected; // Update the selected bank
                        _updateSaveButtonState(); // Enable/disable save button
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Select Bank',
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save', style: TextStyle(color: Colors.black)),
                  onPressed: _isSaveButtonEnabled
                      ? () {
                          _saveAccountDetails(); // Save the bank details
                        }
                      : null, // Disable the button if form is incomplete
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to save account details to Firebase Firestore
  Future<void> _saveAccountDetails() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Get a reference to the users collection in Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Save the bank name and account number in Firestore
        await firestore.collection('users').doc(user.uid).update({
          'bankName': _selectedBank,
          'accountNumber': _accountNumberController.text,
          //  'earnings': updatedEarnings, // Update earnings as well
        });

        // Notify the user that the details have been saved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account details saved successfully!')),
        );

        // Refresh the bank details and earnings
        _getBankDetails();

        // Close the dialog
        Navigator.of(context).pop();
      } catch (e) {
        // Handle any errors that occur during saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving details: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in')),
      );
    }
  }

  // Function to check if the form is filled properly and enable/disable the Save button
  void _updateSaveButtonState() {
    setState(() {
      // The form is valid if the bank is selected and account number is not empty
      _isSaveButtonEnabled =
          _selectedBank != null && _accountNumberController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Personal Information",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            iconSize: 25.0,
            icon: Icon(Icons.video_collection_rounded),
            onPressed: () {
              Get.to(VideoReelsPage());
            },
            color: Colors.black,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 16, top: 25, right: 16),
        child: ListView(
          children: [
            // Full Name Section
            Row(
              children: [
                Icon(Icons.person, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  "",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(color: Colors.black, height: 10, thickness: 2),
            SizedBox(height: 10),
            buildInfoRow(
                "Full Name:", AppConstants.currentUser.getFullNameOfUser()),
            SizedBox(height: 10),
            buildInfoRow("Email:", AppConstants.currentUser.email.toString()),
            SizedBox(height: 10),
            buildInfoRow("About Me:", AppConstants.currentUser.bio.toString()),
            SizedBox(height: 10),
            buildInfoRow("City:", AppConstants.currentUser.state.toString()),
            SizedBox(height: 10),
            buildInfoRow(
                "Country:", AppConstants.currentUser.country.toString()),
            SizedBox(height: 10),
            buildInfoRow("Status:",
                AppConstants.currentUser.isHost ?? false ? "Host" : "Guest"),
            SizedBox(height: 40),

            // Host Section (only display if the user is a host)
            AppConstants.currentUser.isHost ?? false
                ? Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            "Host", // Display "Host" if user is a host
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Divider(color: Colors.black, height: 10, thickness: 2),
                      SizedBox(height: 10),
                      buildInfoRow(
                          "Earnings:",
                          updatedEarnings != null
                              ? NumberFormat('#,###').format(updatedEarnings)
                              : "Not Available"),
                      SizedBox(height: 10),
                      buildInfoRow("Bank:", savedBankName ?? "Not provided"),
                      SizedBox(height: 10),
                      buildInfoRow("Account Number:",
                          savedAccountNumber ?? "Not provided"),
                      SizedBox(height: 5),
                      Text(
                          "* the bank details must tally with the name in this account",
                          style: TextStyle(color: Colors.black, fontSize: 10)),
                      SizedBox(height: 30),
                      Center(
                          child: MaterialButton(
                        onPressed: _showBankDetailsDialog,
                        minWidth: double.infinity,
                        elevation: 10,
                        height: MediaQuery.of(context).size.height / 14,
                        color: Colors.white,
                        child: const Text(
                          '+ Bank',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: Colors.black, width: 2), // Black border
                          borderRadius: BorderRadius.circular(
                              5), // Optional: Rounded corners
                        ),
                      )),
                      SizedBox(height: 30),
                      Center(
                        child: MaterialButton(
                          onPressed: () {
                            Get.to(withdraw());
                          },
                          minWidth: double.infinity,
                          elevation: 10,
                          height: MediaQuery.of(context).size.height / 14,
                          color: Colors.black,
                          child: const Text(
                            'Withdraw',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            "Guest", // Display "Guest" if user is not a host
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Divider(color: Colors.black, height: 10, thickness: 2),
                      SizedBox(height: 10),
                      buildInfoRow("Bank:", savedBankName ?? "Not provided"),
                      SizedBox(height: 10),
                      buildInfoRow("Account Number:",
                          savedAccountNumber ?? "Not provided"),
                      SizedBox(height: 5),
                      Text(
                          "* the bank details must tally with the name in this account",
                          style: TextStyle(color: Colors.black, fontSize: 10)),
                      SizedBox(height: 30),
                      Center(
                          child: MaterialButton(
                        onPressed: _showBankDetailsDialog,
                        minWidth: double.infinity,
                        elevation: 10,
                        height: MediaQuery.of(context).size.height / 14,
                        color: Colors.white,
                        child: const Text(
                          '+ Bank',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: Colors.black, width: 2), // Black border
                          borderRadius: BorderRadius.circular(
                              5), // Optional: Rounded corners
                        ),
                      )),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
                TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
          ),
          Flexible(
              // Allows text to wrap while avoiding overflow
              child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          )),
        ],
      ),
    );
  }
}
