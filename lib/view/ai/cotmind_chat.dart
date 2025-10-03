import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CotmindChat extends StatelessWidget {
  const CotmindChat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Show message for web users
      return Scaffold(
        appBar: AppBar(
          title: const Text("Cotmind Chat"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Cotmind Chat is only available\nin our mobile app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Replace with your Play Store & App Store links
                  // Example: launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.cotmade"));
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Cotmade App"),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile users: load full CotmindChat
    return const CotmindChatMobile();
  }
}

// Keep your existing mobile CotmindChat logic here
class CotmindChatMobile extends StatelessWidget {
  const CotmindChatMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 👉 Put your original CotmindChat code here (functional logic)
    return Scaffold(
      appBar: AppBar(title: const Text("Cotmind Chat")),
      body: const Center(child: Text("Cotmind AI logic here...")),
    );
  }
}
