import 'package:flutter/material.dart';
import 'package:flutter_faq/flutter_faq.dart';
import 'package:cotmade/view/reelsScreen.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
        // leading: Icon(Icons.bac, color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "FAQ",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
              iconSize: 25.0,
              icon: Icon(Icons.video_collection_rounded),
              onPressed: () {
                Get.to(ReelScreen());
              }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          //   Padding(
          //    padding: const EdgeInsets.only(top: 10.0),
          //    child: Text("Frequently Asked Question",
          //        style: TextStyle(color: Colors.black, fontSize: 25.0),
          //       textAlign: TextAlign.center),
          //  ),
          Image.asset("images/fun-fact.gif", width: 90),
          SizedBox(height: 15.0),
          FAQ(
            question: "What is CotMade?",
            answer:
                "CotMade is an innovative platform designed to help people find and book rental properties, particularly focusing on short-term rentals like vacation homes, apartments, or even unique stays like cabins, villas, or cottages. While many rental platforms cater to this market, CotMade distinguishes itself with a tailored user experience, possibly offering features such as detailed property descriptions, user reviews, and advanced search filters. We cater for the African Real Estate Market",
            ansStyle: TextStyle(color: Colors.black), //fontSize: 15),
            queStyle: TextStyle(color: Colors.black), // fontSize: 25),
            showDivider: false,
          ),
          FAQ(
            question: "How does CotMade work?",
            answer:
                "CotMade connects property owners with travelers. Property owners list their homes, apartments, or other types of properties on the platform. Travelers can search for available rentals, filter results based on their preferences (like location, price, amenities), and securely book their stay. Payments and bookings are managed directly through the platform.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Is CotMade available worldwide?",
            answer:
                "Yes, CotMade operates internationally to guests, with listings in African countries. Depending on the region, the platform may feature local properties or international destinations. However, the availability of properties may vary by location in Africa.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "How do I create an account on CotMade?",
            answer:
                "To create an account, simply visit the CotMade website or download the mobile app. Click on Sign Up, and fill the registration form to create an account. Once registered, you can start browsing properties and book your next stay.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Are the rental properties listed on CotMade verified?",
            answer:
                "Yes, CotMade works with property owners and managers to verify the accuracy of each listing. Listings include detailed descriptions, photos, and user reviews to help ensure the property meets your expectations. Additionally, CotMade offers a secure payment process to protect both guests and hosts.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Is it safe to book through CotMade?",
            answer:
                "Yes, CotMade takes security seriously. The platform uses encryption to protect your personal and payment information. Additionally, CotMade offers a secure messaging system between guests and hosts to ensure privacy and transparency. Always ensure you're communicating and making payments directly through the platform to avoid fraud.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Can I cancel my booking?",
            answer:
                "Cancellation policies vary depending on the property owner or manager. You can review the cancellation policy for each property before making a booking. If you need to cancel, you can do so through your account. Depending on the policy, you may be eligible for a partial or full refund.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "What if something goes wrong during my stay?",
            answer:
                "If you encounter issues during your stay, you can contact CotMade’s customer support team for assistance. We strive to resolve problems quickly, whether it's about the property, amenities, or anything else. We also encourage you to communicate directly with the property owner or manager, as they may be able to address your concerns immediately.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "What if something goes wrong during my stay?",
            answer:
                "If you encounter issues during your stay, you can contact CotMade’s customer support team for assistance. We strive to resolve problems quickly, whether it's about the property, amenities, or anything else. We also encourage you to communicate directly with the property owner or manager, as they may be able to address your concerns immediately.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "How can I list my property on CotMade?",
            answer:
                "If you're a property owner or manager, listing your property is easy! Simply sign up on the platform, fill in details about your property (including photos, amenities, and availability), and set your pricing. Once your listing is live, guests can find and book your property.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Are there any hidden fees on CotMade?",
            answer:
                "CotMade is transparent about fees. You will see the total cost of your booking upfront, including any applicable service fees, cleaning fees, or taxes. There are no hidden fees; however, it's always a good idea to review the booking details before confirming your reservation.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question:
                "Can I contact the property owner or host before booking?",
            answer:
                "No, you can only contact the property owner through the messaging system on the CotMade platform after payment and booking has been confirmed. Meanwhile, You can contact our support for any questions about a property and we will respond in real time.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Does CotMade offer long-term rentals?",
            answer:
                "While CotMade primarily focuses on short-term rentals, some property owners may offer longer-term options. You can filter your search to find properties that are available for extended stays, and you can reach out to our customer support directly for longer-term arrangements.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          FAQ(
            question: "Does CotMade offer customer support?",
            answer:
                "Yes, CotMade offers customer support via email, live chat, or phone. If you need assistance with booking, cancellations, or any issues during your stay, our support team is available to help you. We aim to resolve all inquiries as quickly as possible.",
            ansStyle: const TextStyle(color: Colors.black),
            queStyle: const TextStyle(color: Colors.black),
            showDivider: false,
          ),
          SizedBox(height: 60)
        ]),
      ),
    );
  }
}

String data = """"
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
""";
