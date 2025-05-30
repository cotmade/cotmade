import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePromoCodeScreen extends StatefulWidget {
  final String postingId;

  CreatePromoCodeScreen({required this.postingId});

  @override
  _CreatePromoCodeScreenState createState() => _CreatePromoCodeScreenState();
}

class _CreatePromoCodeScreenState extends State<CreatePromoCodeScreen> {
  TextEditingController discountController = TextEditingController();
  TextEditingController usageLimitController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  String promoCode = ""; // The generated promo code
  bool isGenerated = false; // Flag to check if code is generated

  @override
  void initState() {
    super.initState();
  }

  // Function to generate a 6-digit promo code
  String _generatePromoCode() {
    final random = Random();
    final code = List.generate(6, (index) => random.nextInt(10)).join();
    return 'COT-$code';
  }

  // Save or update the promo code and conditions in Firestore
  _createPromoCode() async {
    if (discountController.text.isEmpty ||
        usageLimitController.text.isEmpty ||
        expiryDateController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    final discount = double.tryParse(discountController.text);
    final usageLimit = int.tryParse(usageLimitController.text);
    final expiryDate = DateTime.tryParse(expiryDateController.text);

    if (discount == null || usageLimit == null || expiryDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid input')));
      return;
    }

    // Add the promo code to Firestore
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Query Firestore to check if the promo code with the same postingId exists
    final querySnapshot = await firestore
        .collection('promo')
        .where('postingId', isEqualTo: widget.postingId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // If promo code already exists, update the existing document
      final docId = querySnapshot.docs.first.id; // Get the document ID

      await firestore.collection('promo').doc(docId).update({
        'code': promoCode,
        'discount': discount,
        'usageLimit': usageLimit,
        'expiryDate': Timestamp.fromDate(expiryDate),
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo code updated successfully')));
        Navigator.pop(context); // Go back after updating the promo code
      }).catchError((e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating promo code')));
      });
    } else {
      // If promo code does not exist, create a new document
      await firestore.collection('promo').add({
        'code': promoCode,
        'postingId': widget.postingId,
        'discount': discount,
        'usageLimit': usageLimit,
        'usedCount': 0,
        'expiryDate': Timestamp.fromDate(expiryDate),
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo code created successfully')));
        Navigator.pop(context); // Go back after creating the promo code
      }).catchError((e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error creating promo code')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Promo Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text input for discount
            TextField(
              controller: discountController,
              decoration: InputDecoration(labelText: 'Discount Percentage'),
              keyboardType: TextInputType.number,
            ),
            // Text input for usage limit
            TextField(
              controller: usageLimitController,
              decoration: InputDecoration(labelText: 'Usage Limit'),
              keyboardType: TextInputType.number,
            ),
            // Text input for expiry date
            TextField(
              controller: expiryDateController,
              decoration:
                  InputDecoration(labelText: 'Expiry Date (yyyy-mm-dd)'),
              keyboardType: TextInputType.datetime,
            ),
            // Button to generate promo code
            SizedBox(height: 20),
            isGenerated
                ? Column(
                    children: [
                      Text(
                        'Generated Promo Code: $promoCode',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _createPromoCode,
                        child: Text('Save Promo Code'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        promoCode = _generatePromoCode();
                        isGenerated = true;
                      });
                    },
                    child: Text('Generate Promo Code'),
                  ),
          ],
        ),
      ),
    );
  }
}
