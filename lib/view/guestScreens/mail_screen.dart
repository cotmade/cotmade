import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

sendBookingConfirmationEmail(String userEmail) async {
  String username = 'timothyogbogu@gmail.com';
  String password = 'Jennifer321#'; // or use OAuth2 for better security

  final smtpServer = gmail(username, password); // Using Gmail SMTP server

  final message = Message()
    ..from = Address(username)
    ..recipients.add(userEmail)
    ..subject = 'Booking Confirmation'
    ..text = 'Hello, your booking is confirmed!'
    ..html = '<strong>Hello,</strong><p>Your booking is confirmed!</p>';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent: ' + e.toString());
  }
}
