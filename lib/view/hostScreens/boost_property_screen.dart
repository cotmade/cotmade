import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cotmade/view/hostScreens/boost_success_screen.dart';

class BoostPropertyPage extends StatefulWidget {
  final String postingId;

  BoostPropertyPage({required this.postingId});

  @override
  _BoostPropertyPageState createState() => _BoostPropertyPageState();
}

class _BoostPropertyPageState extends State<BoostPropertyPage> {
  String currency = "";
  double amountInConvertedCurrency = 0.0;
  String postingName = "";
  late final InAppPurchase _inAppPurchase;
  ProductDetails? _productDetails;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  final Customer customer = Customer(
    email: AppConstants.currentUser.email.toString(),
    name: AppConstants.currentUser.getFullNameOfUser(),
    phoneNumber: AppConstants.currentUser.mobileNumber.toString(),
  );

  @override
  void initState() {
    super.initState();
    _fetchCurrencyAndConvertAmount();
    _initializeInAppPurchase();
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrencyAndConvertAmount() async {
    DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .doc(widget.postingId)
        .get();

    if (postingSnapshot.exists) {
      setState(() {
        currency = postingSnapshot['currency'];
        postingName = postingSnapshot['name'];
      });

      double usdAmount = 10.0;

      if (currency != 'USD') {
        double conversionRate = await _getConversionRate('USD', currency);
        setState(() {
          amountInConvertedCurrency = usdAmount * conversionRate;
        });
      } else {
        setState(() {
          amountInConvertedCurrency = usdAmount;
        });
      }
    }
  }

  Future<double> _getConversionRate(String fromCurrency, String toCurrency) async {
    final String apiKey = '65ecc5642a4b0653f9777381';
    final String url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/$fromCurrency';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['conversion_rates'][toCurrency];
    } else {
      throw Exception('Failed to load conversion rate');
    }
  }

  void _initializeInAppPurchase() async {
    _inAppPurchase = InAppPurchase.instance;

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _purchaseSubscription.cancel(),
      onError: (error) => print("IAP Error: $error"),
    );

    final ProductDetailsResponse productDetailsResponse =
        await _inAppPurchase.queryProductDetails({'com.cotmade.cotmade'});

    if (productDetailsResponse.error != null) {
      print("Product details error: ${productDetailsResponse.error!.message}");
    } else if (productDetailsResponse.productDetails.isEmpty) {
      print("No product details found.");
    } else {
      setState(() {
        _productDetails = productDetailsResponse.productDetails.first;
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _deliverProduct(purchaseDetails);
        _inAppPurchase.completePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${purchaseDetails.error?.message}')),
        );
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    DateTime paidDate = DateTime.now();
    DateTime premiumExpiryDate = paidDate.add(Duration(days: 30));

    await FirebaseFirestore.instance.collection('premium').add({
      'postingId': widget.postingId,
      'paidAmount': amountInConvertedCurrency,
      'paymentDate': paidDate,
      'expiryDate': premiumExpiryDate,
    });

    await FirebaseFirestore.instance.collection('postings').doc(widget.postingId).update({
      'premium': 2,
    });

    await sendWelcomeEmail(
      widget.postingId,
      paidDate.toIso8601String(),
      premiumExpiryDate.toIso8601String(),
      amountInConvertedCurrency.toString(),
      customer.email,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment successful!')),
    );

    Get.off(BoostScreen());
  }

  Future<void> _startPaymentProcess() async {
    if (_productDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product not available. Try again later.')),
      );
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _productDetails!,
      applicationUserName: customer.email,
    );

    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> sendWelcomeEmail(
      String postId, String start, String expiry, String amount, String email) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_premium.php");

    final response = await http.post(url, body: {
      "postingID": postId,
      "Start": start,
      "Expiry": expiry,
      "Amount": amount,
      "email": email,
    });

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Premium Subscription')),
      body: Center(
        child: amountInConvertedCurrency > 0.0
            ? Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height / 3,
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
                        child: Image.asset('images/cotty.png', height: 50),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Image.asset('images/chip.png', height: 40),
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
                              postingName,
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
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.yellow[600],
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                minimumSize: Size(150, 40),
                              ),
                              child: Text('Pay Now'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}

// Customer model
class Customer {
  final String email;
  final String name;
  final String phoneNumber;

  Customer({
    required this.email,
    required this.name,
    required this.phoneNumber,
  });
}
