import 'dart:convert';
import 'dart:io';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/guestScreens/trips_screen.dart';
import 'package:cotmade/view/widgets/calendar_ui.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:cotmade/view/guestScreens/payment_success.dart';
import 'package:cotmade/view/guestScreens/mail_screen.dart';
import 'package:cotmade/view/guestScreens/trip_screen.dart';
import 'package:cotmade/view/guestScreens/success_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookListingScreen extends StatefulWidget {
  PostingModel? posting;
  String? hostID;

  BookListingScreen({
    super.key,
    this.posting,
    this.hostID,
  });

  @override
  State<BookListingScreen> createState() => _BookListingScreenState();
}

class _BookListingScreenState extends State<BookListingScreen> {
  PostingModel? posting;
  List<DateTime> bookedDates = [];
  List<DateTime> selectedDates = [];
  List<CalenderUI> calendarWidgets = [];
  final DateTime today = DateTime.now();
  TextEditingController promoCodeController = TextEditingController();
  String promoMessage = '';
  double discountAmount = 0.0;

  String successMessage = '';

  double totalPriceBeforeConversion = 0.0;
  double totalPricep = 0.0;
  double totalPrice = 0.0;
  double totality = 0.0;
  bool isTestMode = true;
  double conversionRate = 1.0; // Start with 1.0 (unconverted value)
  String selectedCurrency =
      ''; // Start with empty, user will select the currency
  List<String> availableCurrencies = [
    'AED',
    'CAD',
    'CLP',
    'COP',
    'EGP',
    'EUR',
    'GHS',
    'GNF',
    'GBP',
    'KES',
    'MAD',
    'MWK',
    'NGN',
    'RWF',
    'SLL',
    'STD',
    'TZS',
    'UGX',
    'USD',
    'XAF',
    'XOF',
    'ZAR',
    'ZMW',
  ]; // List of currencies

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Customize the background color
        duration: Duration(seconds: 3), // Show the snack bar for 3 seconds
      ),
    );
  }

  _buildCalendarWidgets() {
    for (int i = 0; i < 12; i++) {
      calendarWidgets.add(CalenderUI(
        monthIndex: i,
        bookedDates: bookedDates,
        selectDate: _selectDate,
        getSelectedDates: _getSelectedDates,
      ));

      setState(() {});
    }
  }

  List<DateTime> _getSelectedDates() {
    return selectedDates;
  }

  _selectDate(DateTime date) {
    if (selectedDates.contains(date)) {
      selectedDates.remove(date);
    } else {
      selectedDates.add(date);
    }

    selectedDates.sort();
    calculateTotalPriceBeforeConversion(); // Recalculate the price immediately
    setState(() {});
  }

  _loadBookedDates() {
    posting!.getAllBookingsFromFirestore().whenComplete(() {
      bookedDates = posting!.getAllBookedDates();
      _buildCalendarWidgets();
    });
  }

  _makeBooking() {
    if (selectedDates.isEmpty) {
      return;
    }

    posting!
        .makeNewBooking(selectedDates, context, widget.hostID)
        .whenComplete(() {
      Get.back(); // Go back to the previous screen after booking
    });
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    _loadBookedDates();
  }

  Future<String> getHostEmail(String hostID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users") // Firestore collection where user data is stored
          .doc(hostID) // Find the host's document by their ID
          .get();

      if (userDoc.exists) {
        return userDoc["email"]; // Get the host's email from Firestore
      } else {
        return ""; // Return empty string if host not found
      }
    } catch (e) {
      print("Error fetching host email: $e");
      return ""; // Return empty string in case of an error
    }
  }

 Future<double> _fetchConversionRate(String fromCurrency, String toCurrency) async {
  final url = Uri.parse(
      'https://api.exchangerate.host/latest?base=$fromCurrency&symbols=$toCurrency');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data['success'] == true && data['rates'] != null) {
      return data['rates'][toCurrency];
    } else {
      throw Exception("Failed to fetch exchange rate");
    }
  } else {
    throw Exception("Failed to fetch exchange rate");
  }
}


 /* // Fetch conversion rate from ExchangeRate-API
  Future<double> _fetchConversionRate(
      String fromCurrency, String toCurrency) async {
    final url = Uri.parse(
        'https://v6.exchangerate-api.com/v6/65ecc5642a4b0653f9777381/latest/$fromCurrency');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] == 'success' && data['conversion_rates'] != null) {
        return data['conversion_rates'][toCurrency]; // Return the exchange rate
      } else {
        throw Exception("Failed to fetch exchange rate");
      }
    } else {
      throw Exception("Failed to fetch exchange rate");
    }
  } */

  // Currency change handler
  void _onCurrencyChanged(String? newCurrency) {
    setState(() {
      selectedCurrency = newCurrency ?? ''; // Clear currency if null
    });

    if (selectedCurrency.isEmpty) return;

    if (selectedCurrency == posting!.currency) {
      setState(() {
        conversionRate = 1.0; // No conversion needed
      });
    } else {
      _getConversionRateFromExchangeRateAPI(selectedCurrency);
    }
  }

  Future<void> _getConversionRateFromExchangeRateAPI(String toCurrency) async {
    try {
      if (selectedCurrency.isNotEmpty && posting!.currency != null) {
        double rate = await _fetchConversionRate(posting!.currency!,
            selectedCurrency); // Fetch rate based on selected currency
        setState(() {
          conversionRate = rate * 1.2;
        });
      }
    } catch (e) {
      print("Error fetching conversion rate: $e");
      setState(() {
        conversionRate = 1.0; // Fallback to 1.0 in case of an error
      });
    }
  }

  void calculateTotalPriceBeforeConversion() {
    if (selectedDates.isEmpty) {
      totalPriceBeforeConversion = 0.0; // Reset price if no dates are selected
      discountAmount = 0.0;
    } else {
      totality = selectedDates.length * (posting!.price ?? 0) * discountAmount;
      totalPriceBeforeConversion =
          selectedDates.length * (posting!.price ?? 0) - totality;
      totalPrice = totalPriceBeforeConversion * 0.02;
      totalPricep =
          totalPriceBeforeConversion + totalPrice + (posting!.caution ?? 0);
    }

    // Apply the discount to the total price after the promo code
  }

  Future<void> _validatePromoCode(postingId, String promoCode) async {
    if (promoCode.isEmpty) {
      setState(() {
        promoMessage =
            'Please enter a promo code'; // Add message for empty code
      });
      return;
    }

    try {
      final promoSnapshot = await FirebaseFirestore.instance
          .collection('promo') // Ensure this is the correct collection
          .where('code', isEqualTo: promoCode)
          .where('postingId', isEqualTo: postingId)
          .get();

      if (promoSnapshot.docs.isEmpty) {
        setState(() {
          promoMessage =
              'Promo code is invalid'; // Error for invalid promo code
          discountAmount = 0.0; // Reset discount amount
        });
        return;
      }

      final promoDoc = promoSnapshot.docs.first;
      final DateTime expiryDate =
          (promoDoc['expiryDate'] as Timestamp).toDate();
      final currentDate = DateTime.now();

      if (currentDate.isAfter(expiryDate)) {
        setState(() {
          promoMessage =
              'Promo code has expired'; // Error for expired promo code
          discountAmount = 0.0; // Reset discount amount
        });
        return;
      }

      double discountPercentage = promoDoc['discount'] ?? 0;
      discountAmount = discountPercentage / 1000;

      setState(() {
        promoMessage =
            'Promo code applied successfully'; // Show success message
      });

      calculateTotalPriceBeforeConversion(); // Recalculate the total price after discount
    } catch (e) {
      setState(() {
        promoMessage = 'An error occurred while applying the promo code';
        discountAmount = 0.0; // Reset discount on error
      });
      print("Error validating promo code: $e");
    }
  }

  calculateAmountForOverAllStay() async {
    if (selectedDates.isEmpty || selectedCurrency.isEmpty) {
      showError('Please select a currency and date');
      return;
    }

    double totalo =
        selectedDates.length * (posting!.price ?? 0) * discountAmount;
    double totaloo = selectedDates.length * (posting!.price ?? 0) - totalo;
    double totalPriceForAllNights = totaloo + (posting!.caution ?? 0);
    double tota = totaloo * 0.10;
    double totalPriceForAll = totaloo - tota;

    double price = totalPriceForAllNights * conversionRate;
    double priced = price * 0.02;
    double pricedd = priced + price;

    String currency = selectedCurrency;

    final Customer customer = Customer(
        email: AppConstants.currentUser.email.toString(),
        name: AppConstants.currentUser.getFullNameOfUser(),
        phoneNumber: AppConstants.currentUser.mobileNumber.toString());

    Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: "FLWPUBK-5075e726729201f3c2b77df72b4a8da5-X",
      currency: currency,
      redirectUrl: 'https://cotmade.com',
      txRef: Uuid().v1(),
      amount: pricedd.toString(),
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
      await _makeBooking();
      Get.off(SuccessScreen());
    } else {
      Get.back();
      showError("Payment failed. Please try again.");
    }

    setState(() {
      bookingPrice = totalPriceForAll;
    });
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

  //Future<void> sendWelcomeEmail(
  //   String email, String fullName, String hostID) async {
  //  try {
  // Fetch host's email from Firestore
  //  String hostEmail = await getHostEmail(hostID);

  //   if (hostEmail.isEmpty) {
  //     print("⚠️ Host email not found");
  //    return;
  //   }

  //  final url = Uri.parse("https://cotmade.com/app/send_email_guestbook.php");

  // final response = await http.post(url, body: {
  //   "email": email, // Guest email
  //   "guest_name": fullName,
  //    "host_email": hostEmail, // Host email
  //  });

  //  if (response.statusCode == 200) {
  //    print("Email sent successfully to guest and host");
  //  } else {
  //    print("Failed to send email: ${response.body}");
  //   }
  //  } catch (e) {
  //    print("Error sending email: $e");
  //  }
  //}

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
          title: Text(
            "Book ${posting!.name}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text('Sun',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Mon',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Tues',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Wed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Thur',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Fri',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Sat',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: (calendarWidgets.isEmpty)
                        ? Container()
                        : PageView.builder(
                            itemCount: calendarWidgets.length,
                            itemBuilder: (context, index) {
                              return calendarWidgets[index];
                            }),
                  ),
                  SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  const ColoredBox(color: Colors.pinkAccent)),
                          SizedBox(
                            width: 2,
                          ),
                          Text('-'),
                          SizedBox(
                            width: 2,
                          ),
                          Text('Booked Date(s)'),
                        ],
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Amount:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 1),
                      Text(
                        posting!.currency ?? 'available',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${NumberFormat('#,###').format(totalPriceBeforeConversion)}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Service fee:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message:
                                "This fee covers transaction processing and platform support.",
                            child: Icon(Icons.info_outline,
                                color: Colors.black, size: 18),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            posting!.currency ?? 'available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            "${NumberFormat('#,###').format(totalPrice)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // caution fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Caution Fee:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 1),
                      Text(
                        posting!.currency ?? 'available',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${NumberFormat('#,###').format(posting!.caution)}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    height: 1.0, // Height of the line
                    width:
                        double.infinity, // Takes the full width of the screen
                    color: Colors.black, // Color of the line
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total price =",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 1),
                      Text(
                        posting!.currency ?? 'available',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${NumberFormat('#,###').format(totalPricep)}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Enter Promo Code:"),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: promoCodeController,
                          decoration: InputDecoration(
                            hintText: "Enter Promo Code",
                            border: OutlineInputBorder(),
                            errorText: promoMessage.isEmpty
                                ? null
                                : promoMessage, // Show error message if promo is invalid
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  MaterialButton(
                    onPressed: () {
                      _validatePromoCode(posting!.id,
                          promoCodeController.text); // Apply the promo code
                    },
                    minWidth: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.height / 16,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.black, // Border color
                        width: 2, // Border width
                      ),
                      borderRadius: BorderRadius.circular(
                          5), // Optional: adjust corner radius
                    ),
                    child: const Text(
                      'Apply Promo Code',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),

                  SizedBox(height: 1),
                  Row(
                    children: [
                      const Text(
                        "Select Currency:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value:
                            selectedCurrency.isEmpty ? null : selectedCurrency,
                        items: availableCurrencies
                            .map((currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ))
                            .toList(),
                        onChanged: _onCurrencyChanged,
                        hint: const Text(
                          "Select currency",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "select a currency to pay with",
                    style: TextStyle(fontSize: 10),
                  ),
                  SizedBox(height: 1),
                  MaterialButton(
                    onPressed: () {
                      calculateAmountForOverAllStay(); // Trigger the payment calculation
                    },
                    minWidth: double.infinity,
                    height: MediaQuery.of(context).size.height / 14,
                    color: Colors.black,
                    child: const Text(
                      'Proceed to Pay',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 40)
                ],
              ),
            ),
          ),
        ));
  }
}
