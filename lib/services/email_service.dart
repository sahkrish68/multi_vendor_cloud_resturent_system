// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class EmailService {
//   static Future<void> sendOtpEmail(String email, String otp) async {
//     final response = await http.post(
//       Uri.parse('https://api.mailersend.com/v1/email'),
//       headers: {
//         'Authorization': 'mlsn.9fbce76ba8a6903e3c30e13ea58cbef601b58579c18b60157bf9d44bfde0cbd1',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         "from": {
//           "email": "hashsirk@gmail.com",
//           "name": "Khau"
//         },
//         "to": [
//           {
//             "email": email,
//             "name": "User"
//           }
//         ],
//         "subject": "Your OTP Code",
//         "text": "Your OTP is: $otp"
//       }),
//     );

//     if (response.statusCode == 202) {
//       print("✅ Email sent!");
//     } else {
//       print("❌ Failed to send email: ${response.body}");
//     }
//   }
// }
