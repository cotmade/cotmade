import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:cotmade/view/hostScreens/boost_success_screen.dart';

class BoostPropertyPage extends StatefulWidget {
  final String postingId; // Passing postingId from the previous screen
  BoostPropertyPage({required this.postingId});

  @override
  _BoostPropertyPageState createState() => _BoostPropertyPageState();
}

class _BoostPropertyPageState extends State<BoostPropertyPage> {
  String currency = "";
  double amountInConvertedCurrency = 0.0;
  String postingName = ""; // Variable to store the posting name

  @override
  void initState() {
    super.initState();
    _fetchCurrencyAndConvertAmount();
  }

  Future<void> _fetchCurrencyAndConvertAmount() async {
    DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .doc(widget.postingId)
        .get();

    if (postingSnapshot.exists) {
      setState(() {
        currency = postingSnapshot['currency'];
        postingName =
            postingSnapshot['name']; // Assuming 'name' is a field in Firestore
      });

      double usdAmount = 10.0;
      double conversionRate = await _getConversionRate('USD', currency);
      setState(() {
        amountInConvertedCurrency = usdAmount * conversionRate;
      });
    }
  }

  Future<double> _getConversionRate(
      String fromCurrency, String toCurrency) async {
    final String apiKey = '65ecc5642a4b0653f9777381';
    final String url =
        'https://v6.exchangerate-api.com/v6/$apiKey/latest/$fromCurrency';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      double rate = data['conversion_rates'][toCurrency];
      return rate;
    } else {
      throw Exception('Failed to load conversion rate');
    }
  }

  final Customer customer = Customer(
      email: AppConstants.currentUser.email.toString(),
      name: AppConstants.currentUser.getFullNameOfUser(),
      phoneNumber: AppConstants.currentUser.mobileNumber.toString());

  Future<void> _startPaymentProcess() async {
    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: 'FLWPUBK-5075e726729201f3c2b77df72b4a8da5-X',
      currency: currency,
      redirectUrl: 'https://cotmade.com',
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amountInConvertedCurrency.toString(),
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "Live Payment"),
      isTestMode: false,
    );

    final ChargeResponse response = await flutterwave.charge();
    showLoading(response.toString());
    print("Response: ${response.toJson()}");
    print("Status: ${response.status}");

    if (response.success == true || response.status == 'successful') {
      DateTime paidDate = DateTime.now();
      DateTime premiumExpiryDate = paidDate.add(Duration(days: 30));

      FirebaseFirestore.instance.collection('premium').add({
        'postingId': widget.postingId,
        'paidAmount': amountInConvertedCurrency,
        'paymentDate': paidDate,
        'expiryDate': premiumExpiryDate,
      });

      FirebaseFirestore.instance
          .collection('postings')
          .doc(widget.postingId)
          .update({
        'premium': 2,
      });

      // Format the dates as strings
      String paidDateString = paidDate.toIso8601String();
      String premiumExpiryDateString = premiumExpiryDate.toIso8601String();
      String postId = widget.postingId.toString();
      String email = AppConstants.currentUser.email.toString();

      await sendWelcomeEmail(postId, paidDateString, premiumExpiryDateString,
          amountInConvertedCurrency, email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );
      Get.off(BoostScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed! Please try again.')));
    }
  }

  Future<void> sendWelcomeEmail(
      String postId,
      String paidDateString,
      String premiumExpiryDateString,
      double amountInConvertedCurrency,
      String email) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_premium.php");

    final response = await http.post(url, body: {
      "postingID": postId,
      "Start": paidDateString,
      "Expiry": premiumExpiryDateString,
      "Amount": amountInConvertedCurrency,
      "email": email,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

  Future<void> showLoading(String message) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 50,
            child: Text(message),
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) {
    // Format the amount with commas as a thousand separator
    return amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Subscription'),
      ),
      body: Center(
        child: amountInConvertedCurrency > 0.0
            ? Align(
                alignment:
                    Alignment.topCenter, // This aligns the container to the top
                child: Container(
                  padding: EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height /
                      3, // Set container height to half of the screen height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Image.asset(
                          'images/cotty.png',
                          height: 50,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Image.asset(
                          'images/chip.png',
                          height: 40,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '30 Days Premium',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 20,
                                wordSpacing: 12,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              postingName, // Display posting name here
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Amount: $currency ${_formatAmount(amountInConvertedCurrency)}',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _startPaymentProcess,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.black, // Black background
                                foregroundColor:
                                    Colors.yellow[600], // Gold text color
                                padding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal:
                                        16), // Adjust padding for small size
                                minimumSize: Size(150,
                                    40), // Set a small fixed size (optional)
                              ),
                              child: Text('Pay Now'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            : CircularProgressIndicator(),
      ),
    );
  }
}
