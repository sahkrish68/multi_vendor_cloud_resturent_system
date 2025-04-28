import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendOrderConfirmationEmail({
  required String toEmail,
  required String orderId,
  required double total,
  required String restaurantName,
}) async {
  final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
  final apiKey = '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'; // 🛑 Replace with your actual API KEY here

  final body = {
    'personalizations': [
      {
        'to': [
          {'email': toEmail}
        ],
        'subject': 'Order Confirmation - $restaurantName'
      }
    ],
    'from': {'email': 'hashsirk@gmail.com'}, // 🛑 Must be your verified sender email
    'content': [
      {
        'type': 'text/html',
        'value': '''
          <h1>Thank you for your order!</h1>
          <p><strong>Order Number:</strong> $orderId</p>
          <p><strong>Restaurant:</strong> $restaurantName</p>
          <p><strong>Total:</strong> ₹${total.toStringAsFixed(2)}</p>
          <p>We are preparing your food. You will be notified soon!</p>
        '''
      }
    ]
  };

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: json.encode(body),
  );

  if (response.statusCode == 202) {
    print('✅ Email sent successfully!');
  } else {
    print('❌ Failed to send email: ${response.body}');
  }
}
