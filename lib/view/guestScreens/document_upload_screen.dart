import 'dart:io'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/verify_screen.dart';
import 'package:http/http.dart' as http;
import 'package:cotmade/model/app_constants.dart';

class DocumentUploadScreen extends StatefulWidget {
  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isUploading = false;

  String email = AppConstants.currentUser.email.toString();
  String name = AppConstants.currentUser.getFullNameOfUser();
  String userCountry = ""; // Variable to hold user's country
  List<String> acceptedDocuments =
      []; // List of documents accepted for the user's country
  String selectedCountry = ""; // Country selected by the user

  // Map of African countries and their accepted documents for verification
  final Map<String, List<String>> countryDocumentMap = {
    'Nigeria': ['International Passport', 'Driver\'s License', 'NIN slip'],
    'South Africa': ['Identity Document (ID)', 'Driver\'s License', 'Passport'],
    'Kenya': ['National ID', 'Passport', 'Driver\'s License'],
    'Egypt': ['National ID', 'Driver\'s License', 'Passport'],
    'Ghana': ['National ID', 'Passport', 'Driver\'s License'],
    'Uganda': ['National ID', 'Passport', 'Driver\'s License'],
    'Tanzania': ['National ID', 'Driver\'s License', 'Passport'],
    'Ethiopia': ['National ID', 'Driver\'s License', 'Passport'],
    'Senegal': ['National ID', 'Passport', 'Driver\'s License'],
    'Zambia': ['National ID', 'Passport', 'Driver\'s License'],
    // Add more countries and accepted documents here...
  };

  @override
  void initState() {
    super.initState();
    _fetchUserCountry();
  }

  Future<void> _fetchUserCountry() async {
    try {
      // Fetch user's country from Firestore (assuming it's stored in user profile)
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      setState(() {
        userCountry = userDoc['country'] ?? 'Unknown Country';
        selectedCountry = userCountry; // Default to user's country
      });

      // Set the accepted documents based on the user's country
      _setAcceptedDocuments(userCountry);
    } catch (e) {
      print("Error fetching user country: $e");
    }
  }

  // Function to set accepted documents based on country
  void _setAcceptedDocuments(String country) {
    // Check if the country exists in the map and set accepted documents
    if (countryDocumentMap.containsKey(country)) {
      setState(() {
        acceptedDocuments = countryDocumentMap[country]!;
      });
    } else {
      setState(() {
        acceptedDocuments = [
          'International Passport',
          'Driver\'s License',
          'NIN slip'
        ];
      });
    }
  }

  Future<void> uploadDocument() async {
    if (_imageFile == null) {
      Get.snackbar("Error", "Please select a document or image to upload.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(
          'user_uploads/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = ref.putFile(File(_imageFile!.path));

      await uploadTask;

      String downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'documentUrl': downloadUrl,
        'documentStatus': 'Under review',
        'isCurrentlyHosting': false,
      });

      setState(() {
        _isUploading = false;
      });

      await sendWelcomeEmail(email, name);

      Get.snackbar("Success", "Your document is being reviewed.");
      Get.off(VerifyScreen());
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Get.snackbar("Error", "Failed to upload the document.");
    }
  }

  Future<void> sendWelcomeEmail(String email, String name) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_hostverif.php");

    final response = await http.post(url, body: {
      "email": email,
      "name": name,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Host Verification")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'images/idd.jpg',
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Card(
                color: Color(0xcaf6f6f6),
                elevation: 4,
                shadowColor: Colors.black12,
                child: InkWell(
                  onTap: () async {
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      _imageFile = pickedFile;
                    });
                  },
                  child: ListTile(
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            "Add a file",
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_box),
                      SizedBox(width: 10),
                      Text("${_imageFile!.name}",
                          style: TextStyle(color: Colors.pinkAccent)),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              Card(
                color: Color(0xcaf6f6f6),
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, size: 30),
                          SizedBox(width: 10),
                          Text(
                            "What documents do we accept?",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Country: $selectedCountry",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dropdown for selecting country
                      DropdownButton<String>(
                        value: selectedCountry,
                        onChanged: (newValue) {
                          setState(() {
                            selectedCountry = newValue!;
                            _setAcceptedDocuments(selectedCountry);
                          });
                        },
                        items: countryDocumentMap.keys.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Please upload a clear document (pdf) or clear image (jpg,png) of any of the listed documents below:\n \n"
                        "${acceptedDocuments.join('\n')}",
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: uploadDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: Text(
                            "Upload",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 22.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20), // Extra space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
