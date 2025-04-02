import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cotmade/model/app_constants.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String? selectedTopic;

  final List<String> feedbackTopics = [
    "App Usability",
    "Bug Report",
    "Feature Request",
    "Customer Support",
    "Host Experience",
    "Other"
  ];

  void _submitFeedback() async {
    if (selectedTopic == null || _feedbackController.text.isEmpty) {
      Get.snackbar("Error", "Please select a topic and enter feedback",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xe1f8f6f6),
          colorText: Colors.black);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'topic': selectedTopic,
        'feedback': _feedbackController.text,
        'name': AppConstants.currentUser.getFullNameOfUser(),
        'email': AppConstants.currentUser.email.toString(),
        'mobileNumber': AppConstants.currentUser.mobileNumber.toString(),
        'country': AppConstants.currentUser.country.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      await sendWelcomeEmail(
          AppConstants.currentUser.email.toString(),
          AppConstants.currentUser.getFullNameOfUser(),
          AppConstants.currentUser.mobileNumber.toString(),
          AppConstants.currentUser.country.toString(),
          _feedbackController.text);
      Get.snackbar("Success", "Feedback submitted successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xe1f8f6f6),
          colorText: Colors.black);

      _feedbackController.clear();
      setState(() => selectedTopic = null);
    } catch (e) {
      print("Error submitting feedback: $e");
      Get.snackbar("Error", "Something went wrong. Try again later.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xe1f8f6f6),
          colorText: Colors.black);
    }
  }

  Future<void> sendWelcomeEmail(String email, String name, String mobileNumber,
      String country, String _feedbackController) async {
    final url = Uri.parse("https://cotmade.com/app/send_email_feedback.php");

    final response = await http.post(url, body: {
      "email": email,
      "name": name,
      "mobileNumber": mobileNumber,
      "note": _feedbackController,
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
      appBar: AppBar(title: Text("Give Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select a Topic:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedTopic,
              hint: Text("Choose a topic"),
              isExpanded: true,
              items: feedbackTopics.map((String topic) {
                return DropdownMenuItem<String>(
                  value: topic,
                  child: Text(topic),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedTopic = value);
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Your Feedback",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
