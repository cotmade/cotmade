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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );
      Get.off(BoostScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed! Please try again.')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Subscription'),
      ),
      body: Center(
        child: amountInConvertedCurrency > 0.0
            ? Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
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
                      child: Text(
                        '30 Days Premium',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 20,
                          wordSpacing: 12,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Amount: $currency $amountInConvertedCurrency',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _startPaymentProcess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Black background
                              foregroundColor:
                                  Colors.yellow[600], // Gold text color
                              padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal:
                                      16), // Adjust padding for small size
                              minimumSize: Size(
                                  150, 40), // Set a small fixed size (optional)
                            ),
                            child: Text('Pay Now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
