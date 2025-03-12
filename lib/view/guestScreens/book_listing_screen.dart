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

  //String demail = AppConstants.currentUser.email.toString();
  //String fname = AppConstants.currentUser.getFullNameOfUser();
  String successMessage = '';

  double totalPriceBeforeConversion = 0.0;
  double totalPricep = 0.0;
  double totalPrice = 0.0;
  bool isTestMode = true;
  double conversionRate = 1.0; // Start with 1.0 (unconverted value)
  String selectedCurrency =
      ''; // Start with empty, user will select the currency
  List<String> availableCurrencies = [
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

  // Fetch conversion rate from ExchangeRate-API
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
  }

  // Currency change handler
  void _onCurrencyChanged(String? newCurrency) {
    setState(() {
      selectedCurrency = newCurrency ?? ''; // Clear currency if null
    });

    if (selectedCurrency.isEmpty)
      return; // Don't do anything if currency is empty

    // Check if the selected currency is the same as the posting's currency
    if (selectedCurrency == posting!.currency) {
      setState(() {
        conversionRate = 1.0; // No conversion needed
      });
    } else {
      // Only fetch conversion rate if the selected currency is different from posting's currency
      _getConversionRateFromExchangeRateAPI(selectedCurrency);
    }
  }

  // Fetch the conversion rate and update the state
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
    } else {
      totalPriceBeforeConversion = selectedDates.length * (posting!.price ?? 0);
      totalPrice = totalPriceBeforeConversion * 0.02;
      totalPricep = totalPriceBeforeConversion + totalPrice;
    }
    // No need for setState here, just ensure it's updated real-time
  }

  // Calculate amount based on selected currency and conversion
  calculateAmountForOverAllStay() async {
    if (selectedDates.isEmpty || selectedCurrency.isEmpty) {
      showError('Please select a currency and date');
      return;
    }

    double totalPriceForAllNights =
        selectedDates.length * (posting!.price ?? 0);

    double totalPriceForAll =
        selectedDates.length * (posting!.price ?? 0) * 0.13;

    double price =
        totalPriceForAllNights * conversionRate; // Apply conversion rate

    double priced = price * 0.02;

    double pricedd = priced + price;

    String currency = selectedCurrency; // Use the selected currency

    // Create Flutterwave payment configuration
    final Customer customer = Customer(
        email: AppConstants.currentUser.email.toString(),
        name: AppConstants.currentUser.getFullNameOfUser(),
        phoneNumber: AppConstants.currentUser.mobileNumber.toString());

    Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: "FLWPUBK_TEST-44e5cfe64922be6c4e8f4ad7dc2c0890-X",
      currency: currency,
      redirectUrl: 'https://cotmade.com',
      txRef: Uuid().v1(),
      amount: pricedd.toString(), // Use the converted price
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "Test Payment"),
      isTestMode: true,
    );

    final ChargeResponse response =
        await flutterwave.charge(); // Timeout after 30 seconds
    showLoading(response.toString());
    print("Response: ${response.toJson()}");
    print("Status: ${response.status}");

    // Adjust your logic to check for 'successful' and 'true'
    if (response.success == true || response.status == 'successful') {
      await _makeBooking(); // Make the booking
      await sendWelcomeEmail(
          AppConstants.currentUser.email.toString(),
          AppConstants.currentUser.getFullNameOfUser(),
          widget.hostID.toString());
      Get.off(SuccessScreen()); // Navigate to the success screen
    } else {
      Get.back(); // Go back if the payment fails
      showError("Payment failed. Please try again.");
    }

    setState(() {
      bookingPrice = totalPriceForAllNights;
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

  Future<void> sendWelcomeEmail(
      String email, String fullName, String hostID) async {
    try {
      // Fetch host's email from Firestore
      String hostEmail = await getHostEmail(hostID);

      if (hostEmail.isEmpty) {
        print("⚠️ Host email not found");
        return;
      }

      final url = Uri.parse("https://cotmade.com/app/send_email_guestbook.php");

      final response = await http.post(url, body: {
        "email": email, // Guest email
        "guest_name": fullName,
        "host_email": hostEmail, // Host email
      });

      if (response.statusCode == 200) {
        print("Email sent successfully to guest and host");
      } else {
        print("Failed to send email: ${response.body}");
      }
    } catch (e) {
      print("Error sending email: $e");
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
            begin: FractionalOffset(0, 0),
            end: FractionalOffset(1, 0),
            stops: [0, 1],
            tileMode: TileMode.clamp,
          )),
        ),
        title: Text(
          "Book ${posting!.name}",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Tues', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Thur', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            child: const ColoredBox(color: Colors.pinkAccent)),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 1),
                    Text(
                      posting!.currency ?? 'available',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${NumberFormat('#,###').format(totalPriceBeforeConversion)}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "service fee:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 1),
                    Text(
                      posting!.currency ?? 'available',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${NumberFormat('#,###').format(totalPrice)}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  height: 1.0, // Height of the line
                  width: double.infinity, // Takes the full width of the screen
                  color: Colors.black, // Color of the line
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total price =",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 1),
                    Text(
                      posting!.currency ?? 'available',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${NumberFormat('#,###').format(totalPricep)}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 1),
                Row(
                  children: [
                    const Text("Select Currency:"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedCurrency.isEmpty ? null : selectedCurrency,
                      items: availableCurrencies
                          .map((currency) => DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency),
                              ))
                          .toList(),
                      onChanged: _onCurrencyChanged,
                      hint: const Text("Select currency"),
                    ),
                  ],
                ),
                Text(
                  "you can select a currency to pay with",
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
