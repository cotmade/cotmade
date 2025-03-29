import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpCentreScreen extends StatelessWidget {
  final List<Map<String, String>> helpTopics = [
    {
      "title": "How to use the app",
      "details": "Learn how to navigate and use our app effectively."
    },
    {
      "title": "Booking Issues",
      "details": "Troubleshoot issues related to booking a property."
    },
    {
      "title": "Payment & Refunds",
      "details":
          "Information about payments, refunds, and transaction security."
    },
    {
      "title": "Account & Security",
      "details": "Guidelines on managing your account and keeping it secure."
    },
    {
      "title": "Contact Support",
      "details": "Reach out to us for further assistance."
    },
  ];

  void _handleTopicTap(BuildContext context, String title, String details) {
    Get.to(() => HelpDetailScreen(title: title, details: details));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Help Centre")),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: helpTopics.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final topic = helpTopics[index];
          return ListTile(
            title: Text(topic["title"]!,
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              if (topic["title"] == "Contact Support") {
                _showContactSupportDialog(context);
              } else {
                _handleTopicTap(context, topic["title"]!, topic["details"]!);
              }
            },
          );
        },
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Contact Support"),
        content: Text(
            "You can reach us via:\n\n📧 Email: support@cotmade.com\n📞 Phone: +234 903 479 5131"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Close"))
        ],
      ),
    );
  }
}

class HelpDetailScreen extends StatelessWidget {
  final String title;
  final String details;

  HelpDetailScreen({required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(details, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
