import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Terms of Service'),
            _buildParagraph(
                'These Terms of Service ("Terms") govern your access to and use of CotMade, a platform that connects users with short-term rental properties. By accessing or using the App, you agree to comply with and be bound by these Terms. If you do not agree to these Terms, you must not access or use the App.'),
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildParagraph(
                'By using the App, you agree to these Terms and the Privacy Policy of CotMade. If you are using the App on behalf of an organization, you represent and warrant that you have the authority to bind that organization to these Terms.'),
            _buildSectionTitle('2. Eligibility'),
            _buildParagraph(
                'You must be at least 18 years old to use the App. By accessing or using the App, you represent and warrant that you are 18 years of age or older.'),
            _buildSectionTitle('3. Account Registration'),
            _buildParagraph(
                'To use certain features of the App, you may be required to create an account. You agree to provide accurate and complete information when registering and to keep your account information up-to-date. You are responsible for safeguarding your account and for all activities that occur under your account.'),
            _buildSectionTitle('4. User Responsibilities'),
            _buildBulletPoints([
              'Engage in any unlawful activity, including fraud, harassment, or violating any applicable local, state, or national laws.',
              'Impersonate any person or entity, or provide false information.',
              'Upload or transmit viruses, malware, or any harmful code to the App.',
              'Use the App for any purpose other than its intended use of facilitating booking or renting properties.',
            ]),
            _buildSectionTitle('5. Bookings and Transactions'),
            _buildBulletPoints([
              'Hosts: If you are listing a property, you agree to provide accurate, complete, and up-to-date details about the property. You must also ensure the property complies with all local regulations and safety standards.',
              'Guests: If you are booking a property, you agree to pay the listed price and follow any specific rules and requirements set by the host.',
              'Payment: Payments for bookings are processed via the App’s payment gateway. You agree to pay all applicable fees and charges related to your bookings.',
              'Cancellations: Hosts and guests are bound by the cancellation policy specified in the listing or booking confirmation.',
            ]),
            _buildSectionTitle('6. Fees and Charges'),
            _buildParagraph(
                'CotMade may charge service fees, booking fees, or other charges for using the App. These fees are disclosed before completing any transaction and are non-refundable, except as outlined in the cancellation policy.'),
            _buildSectionTitle('7. Cancellation and Refunds'),
            _buildParagraph(
                'Refunds may be provided depending on the host’s cancellation policy and the circumstances surrounding the booking. Any refund requests must be made within 10 days of the booking completion.'),
            _buildSectionTitle('8. Intellectual Property'),
            _buildParagraph(
                'All content available on the App, including text, graphics, logos, images, and software, is the property of CotMade or its licensors and is protected by intellectual property laws. You may not copy, modify, distribute, or otherwise exploit the content without permission.'),
            _buildSectionTitle('9. Dispute Resolution'),
            _buildParagraph(
                'Any disputes arising out of or related to these Terms or the App shall be resolved through binding arbitration in [jurisdiction]. You agree to waive any right to participate in class actions or collective claims.'),
            _buildSectionTitle('10. Privacy and Data Collection'),
            _buildParagraph(
                'CotMade collects and uses personal data in accordance with our Privacy Policy. By using the App, you consent to the collection and use of your data as outlined in the Privacy Policy.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
