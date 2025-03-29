import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/view_model/user_view_model.dart';
import 'package:cotmade/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class withdraw extends StatefulWidget {
  const withdraw({super.key});

  @override
  State<withdraw> createState() => _withdrawState();
}

class _withdrawState extends State<withdraw> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  //String email = AppConstants.currentUser.email.toString();
  //String fname = AppConstants.currentUser.getFullNameOfUser();
  String? userID = AppConstants.currentUser.id;
  double? currentBalance;
  bool isBalanceLoaded = false; // Add this line

  @override
  void initState() {
    super.initState();
    _getUserBalance();
  }

  // Fetch current user's balance from Firestore
  Future<void> _getUserBalance() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userID = user.uid;
      try {
        // Listen for real-time updates on the user's balance
        FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              currentBalance = snapshot['earnings']?.toDouble();
              isBalanceLoaded = true; // Set to true once data is fetched
            });
          }
        });
      } catch (e) {
        print("Error fetching user balance: $e");
      }
    }
  }

  // Function to save withdrawal details to Firestore
  Future<void> _saveWithdrawalDetails(double withdrawalAmount) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userID = user.uid;

        // Create a new withdrawal document
        DocumentReference withdrawalDocRef =
            await FirebaseFirestore.instance.collection('withdrawals').add({
          'userID': userID,
          'amount': withdrawalAmount,
          'date': FieldValue.serverTimestamp(),
          'status': 'pending', // Assuming status is 'pending' initially
          'Name': AppConstants.currentUser.getFullNameOfUser(),
        });

        // Get the documentID of the newly created document
        String withdrawalDocumentID = withdrawalDocRef.id;

        // Update user's balance
        double balanceUpdated = currentBalance! - withdrawalAmount;
        await _updateBalance(balanceUpdated);
        // Send email
        await sendWelcomeEmail(
            AppConstants.currentUser.email.toString(),
            AppConstants.currentUser.getFullNameOfUser(),
            withdrawalAmount,
            withdrawalDocumentID);

        Get.snackbar(
          "Success",
          "Withdrawal request submitted successfully",
          snackPosition: SnackPosition.TOP,
          colorText: Colors.black,
          backgroundColor: Color(0xe1f8f6f6),
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      print("Error saving withdrawal details: $e");
      Get.snackbar(
        "Success",
        "Withdrawal request submitted successfully",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
        backgroundColor: Color(0xe1f8f6f6),
        margin: const EdgeInsets.all(10),
      );
    }
  }

  // Update balance in Firestore
  Future<void> _updateBalance(double updatedBalance) async {
    try {
      if (userID != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .update({'earnings': updatedBalance});
      }
    } catch (e) {
      print("Error updating balance: $e");
    }
  }

  Future<void> sendWelcomeEmail(String email, String fname,
      double withdrawalAmount, String withdrawalDocumentID) async {
    final url =
        Uri.parse("https://cotmade.com/app/send_email_hostwithdraw.php");

    final response = await http.post(url, body: {
      "email": email,
      "fname": fname,
      "withdrawalAmount": withdrawalAmount.toString(),
      "transactionID": withdrawalDocumentID,
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
          "Withdraw",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet section
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Wallet",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 3),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Current Balance",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.white)),
                    Row(
                      children: [
                        //currency symbol here in the text
                        Text("",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(
                            isBalanceLoaded // Use isBalanceLoaded to check if balance is fetched
                                ? NumberFormat('#,###').format(currentBalance)
                                : "loading",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              Text("* we pay in the currency your listings exist.",
                  style: TextStyle(color: Colors.green, fontSize: 13)),
              SizedBox(height: 20),

              // Withdraw Amount Section
              Text("Withdraw Amount",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelText: 'Amount',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty || value.contains('-')) {
                      return 'Please enter a valid amount';
                    } else if (value.contains('.')) {
                      return 'Please enter a number without decimal';
                    } else if (!value.isNumericOnly) {
                      return 'Please enter a numeric value';
                    } else if (double.parse(value) > 10000) {
                      return 'Please enter a value less than 10000';
                    } else if (currentBalance != null &&
                        double.parse(value) > currentBalance!) {
                      return 'Insufficient Balance';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 15),

              // Predefined Amount Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () {
                        _amountController.text = "1000";
                      },
                      child: Text("1,000",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.black)),
                      style: TextButton.styleFrom(
                        shape: StadiumBorder(),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                      )),
                  TextButton(
                      onPressed: () {
                        _amountController.text = "2000";
                      },
                      child: Text("2,000",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.black)),
                      style: TextButton.styleFrom(
                        shape: StadiumBorder(),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                      )),
                  TextButton(
                      onPressed: () {
                        _amountController.text = "5000";
                      },
                      child: Text("5,000",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.black)),
                      style: TextButton.styleFrom(
                        shape: StadiumBorder(),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                      )),
                  TextButton(
                      onPressed: () {
                        _amountController.text = "10000";
                      },
                      child: Text("10,000",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.black)),
                      style: TextButton.styleFrom(
                        shape: StadiumBorder(),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                      )),
                ],
              ),
              SizedBox(height: 20),

              // Withdraw Button
              SizedBox(
                height: 50,
                child: MaterialButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      double withdrawalAmount =
                          double.parse(_amountController.text);

                      // Update balance after withdrawal
                      double balanceUpdated =
                          currentBalance! - withdrawalAmount;

                      if (balanceUpdated < 0) {
                        Get.snackbar(
                          "Error",
                          "Insufficient Balance",
                          snackPosition: SnackPosition.TOP,
                          colorText: Colors.black,
                          backgroundColor: Color(0xe1f8f6f6),
                          margin: const EdgeInsets.all(10),
                        );
                        return;
                      }

                      // Save withdrawal details to Firestore
                      _saveWithdrawalDetails(withdrawalAmount);

                      // Reset amount field and close screen
                      setState(() {
                        _amountController.text = "";
                      });
                      Get.back();
                    }
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

              SizedBox(height: 40),

              // Withdrawal History Section
              Text("Withdrawal History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('withdrawals')
                    .where('userID', isEqualTo: AppConstants.currentUser.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    var withdrawalHistory = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: withdrawalHistory.length,
                      itemBuilder: (context, index) {
                        var transaction = withdrawalHistory[index].data()
                            as Map<String, dynamic>;
                        // Include the document ID (transactionID)
                        String transactionID = withdrawalHistory[index].id;
                        return Card(
                          color: Color(0xcaf6f6f6),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                                "${transaction['amount'] != null ? NumberFormat('#,###').format(transaction['amount']) : 'Not Available'}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date: ${transaction['date'].toDate()}"),
                                Text(
                                    "Transaction ID: $transactionID"), // Display transaction ID beneath date
                              ],
                            ),
                            trailing: Text(
                              transaction['status'],
                              style: TextStyle(
                                color: transaction['status'] == 'completed'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Center(
                      child: Text("No withdrawal history available."));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
