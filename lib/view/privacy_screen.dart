import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy Policy")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Privacy Policy",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildSection("Last Updated", "March 2025"),
              _buildSection("1. Information We Collect",
                  "We collect different types of information to provide and improve our services to you."),
              _buildSubSection(
                  "1.1 Personal Information",
                  "Identity Information: Full name, email address, phone number, date of birth.\n"
                      "Payment Information: Credit/debit card details, billing address, payment history.\n"
                      "Account Information: Username, password, preferences, and booking history.\n"
                      "Profile Information: Profile picture, communication preferences, and other voluntarily provided details."),
              _buildSubSection(
                  "1.2 Booking Information",
                  "Reservation Details: Dates, location, accommodation type, and booking status.\n"
                      "Guest Information: Names, ages, and special requirements of additional guests.\n"
                      "Communication History: Messages exchanged with property owners, hosts, or other users."),
              _buildSubSection(
                  "1.3 Usage and Technical Information",
                  "Device and Log Data: IP address, browser type, operating system, device type.\n"
                      "Cookies and Tracking: We use cookies to enhance experience, analyze patterns, and display relevant ads."),
              _buildSubSection("1.4 Location Data",
                  "We may collect location data for services like nearby properties, travel suggestions, or localized pricing."),
              _buildSection("2. How We Use Your Information",
                  "We use the collected information for various purposes, including providing services, personalization, and legal compliance."),
              _buildSubSection(
                  "2.1 Providing Services",
                  "Facilitating bookings, cancellations, and customer support.\n"
                      "Managing payments and refunds.\n"
                      "Communicating booking confirmations, reminders, or changes."),
              _buildSubSection(
                  "2.2 Personalizing Experience",
                  "Customizing content, offers, and recommendations based on your preferences.\n"
                      "Providing targeted ads or notifications."),
              _buildSubSection(
                  "2.3 Communication",
                  "Sending promotional materials, updates about properties, or relevant news.\n"
                      "Responding to inquiries, feedback, or requests."),
              _buildSubSection("2.4 Legal Compliance",
                  "Ensuring compliance with laws, protecting from fraud, and ensuring safe transactions."),
              _buildSubSection("2.5 Analytics and Improvement",
                  "Analyzing usage trends to improve functionality, design, and user experience."),
              _buildSection("3. How We Share Your Information",
                  "We respect your privacy and do not sell your personal data. However, we may share data with service providers, hosts, or legal entities when necessary."),
              _buildSubSection("3.1 Service Providers",
                  "We may share details with third-party vendors (e.g., payment processors, hosting providers) to operate our platform."),
              _buildSubSection("3.2 Property Owners/Hosts",
                  "To facilitate bookings, we share guest names, contact details, and stay dates with hosts."),
              _buildSubSection("3.3 Business Transfers",
                  "In case of a merger, acquisition, or asset sale, personal data may be transferred."),
              _buildSubSection("3.4 Legal and Security Obligations",
                  "We may disclose information if required by law or to protect rights and safety."),
              _buildSubSection("3.5 Marketing and Third-Party Partners",
                  "With your consent, we may share data with marketing partners for promotional offers."),
              _buildSection("4. Data Security",
                  "We take reasonable precautions to protect your personal data from unauthorized access, loss, or misuse."),
              _buildSubSection("Security Measures",
                  "Using encryption for payment data, secure storage, and monitoring potential security breaches."),
              _buildSection("5. Your Rights",
                  "You have rights regarding your personal data, including access, correction, and deletion."),
              _buildSubSection("5.1 Access and Correction",
                  "You can access, review, and update your account information through profile settings."),
              _buildSubSection("5.2 Deletion",
                  "You can request account deletion, though some data may be retained for legal reasons."),
              _buildSubSection("5.3 Opt-out of Marketing",
                  "You can opt-out of promotional communications at any time."),
              _buildSubSection("5.4 Data Portability",
                  "You can request a copy of your data in a structured format."),
              _buildSubSection("5.5 Revocation of Consent",
                  "You can withdraw consent for data processing, but this may affect platform features."),
              _buildSubSection("5.6 Right to Object",
                  "You can object to data processing, particularly for direct marketing."),
              _buildSection("6. Cookies and Tracking Technologies",
                  "We use cookies to enhance experience, personalize content, and analyze patterns."),
              _buildSubSection(
                  "6.1 Types of Cookies Used",
                  "Essential Cookies: Required for platform functionality.\n"
                      "Performance Cookies: Help us improve performance.\n"
                      "Targeting Cookies: Used for advertising and personalized content."),
              _buildSubSection("6.2 Managing Cookies",
                  "You can manage cookie settings through your browser or device settings."),
              _buildSection("7. Third-Party Links",
                  "Our platform may contain links to third-party websites. We are not responsible for their privacy practices."),
              _buildSection("8. Children’s Privacy",
                  "Our platform is not intended for children under 16. If we collect data from minors, we will delete it."),
              _buildSection("9. Changes to This Privacy Policy",
                  "We may update our Privacy Policy periodically. Continuing to use the platform means you accept changes."),
              _buildSection("10. Contact Us",
                  "For inquiries or data rights, contact us at support@cotmade.com."),
              _buildSection("11. Cookie Policy",
                  "Effective Date: January 2025. We use cookies for tracking and enhancing user experience."),
              _buildSection("Acknowledgment",
                  "By using our platform, you acknowledge that you have read and understood this Privacy Policy."),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(content, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text(content, style: TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
