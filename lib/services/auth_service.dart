import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal(); // private constructor

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedPaymentMethod;

  /// ✅ Create Order Method
  Future<String> createOrder({
  required String userId,
  required String restaurantId,
  required String restaurantName,
  required String address,
  required String paymentMethod,
  required List<Map<String, dynamic>> items,
  required double total,
}) async {
  final now = Timestamp.now();
  final orderId = _firestore.collection('orders').doc().id;

  final orderData = {
    'orderId': orderId,
    'userId': userId,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'shippingAddress': address,
    'paymentMethod': paymentMethod,
    'items': items,
    'total': total,
    'status': 'pending',
    'createdAt': now,
    'updatedAt': now,
  };

  final batch = _firestore.batch();

  // Save to top-level orders
  batch.set(_firestore.collection('orders').doc(orderId), orderData);

  // Save to user's orders
  batch.set(
    _firestore.collection('users').doc(userId).collection('orders').doc(orderId),
    {
      'orderId': orderId,
      'restaurantName': restaurantName,
      'total': total,
      'status': 'pending',
      'createdAt': now,
    },
  );

  // Save to restaurant's orders
  batch.set(
    _firestore.collection('restaurants').doc(restaurantId).collection('orders').doc(orderId),
    {
      'orderId': orderId,
      'userId': userId,
      'total': total,
      'status': 'pending',
      'createdAt': now,
    },
  );

  await batch.commit();
  print("✅ Order created: $orderId");

  return orderId; // 🛑 return the created orderId
}


  /// ✅ Send OTP to Email
  Future<void> sendOtpToEmail(String email) async {
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      final expiresAt = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;

      await _firestore.collection('emailOtps').doc(email).set({
        'otp': otp,
        'expiresAt': expiresAt,
      });

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "service_id": "service_bkoesqf",
          "template_id": "template_b1ds35k",
          "user_id": "FpkIMUsaeaDnbMnOF",
          "template_params": {
            "user_email": email,
            "user_otp": otp,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send OTP email");
      }
    } catch (e) {
      print("❌ sendOtpToEmail failed: $e");
      rethrow;
    }
  }

  /// ✅ Register a New Customer
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection('users').doc(result.user?.uid).set({
        'uid': result.user?.uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'userType': 'customer',
        'otpVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await sendOtpToEmail(email);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed. Please try again',
      );
    }
  }

  /// ✅ Register a Trader
  Future<User?> registerTrader({
    required String email,
    required String password,
    required String businessName,
    required String phone,
    required String address,
    required String businessType,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection('traders').doc(result.user?.uid).set({
        'uid': result.user?.uid,
        'email': email.trim(),
        'businessName': businessName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'businessType': businessType.trim(),
        'userType': 'trader',
        'isApproved': false,
        'otpVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await sendOtpToEmail(email);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Trader registration failed. Please try again',
      );
    }
  }

  Future<void> sendOrderConfirmationEmail({
  required String toEmail,
  required String orderId,
  required String restaurantName,
  required double total,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "service_id": "service_bkoesqf",
        "template_id": "template_ueqb6ee", // 👉 You will create new Template ID for order confirmation
        "user_id": "FpkIMUsaeaDnbMnOF",
        "template_params": {
          "user_email": toEmail,
          "order_id": orderId,
          "restaurant_name": restaurantName,
          "total_amount": total.toStringAsFixed(2),
        }
      }),
    );

    if (response.statusCode != 200) {
      print('❌ Failed to send confirmation email');
    } else {
      print('✅ Order confirmation email sent successfully');
    }
  } catch (e) {
    print('❌ sendOrderConfirmationEmail error: $e');
  }
}


  /// ✅ Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    final doc = await _firestore.collection('emailOtps').doc(email).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    if (DateTime.now().millisecondsSinceEpoch > data['expiresAt'] || data['otp'] != otp) {
      return false;
    }

    final userRecord = await _firestore.collection('users').where('email', isEqualTo: email).get();
    final traderRecord = await _firestore.collection('traders').where('email', isEqualTo: email).get();

    if (userRecord.docs.isNotEmpty) {
      await userRecord.docs.first.reference.update({'otpVerified': true});
    } else if (traderRecord.docs.isNotEmpty) {
      await traderRecord.docs.first.reference.update({'otpVerified': true});
    }

    await _firestore.collection('emailOtps').doc(email).delete();
    return true;
  }

  /// ✅ Login
  Future<User?> login(String email, String password, {bool isTrader = false}) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userDoc = await _firestore
          .collection(isTrader ? 'traders' : 'users')
          .doc(result.user?.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'user-mismatch', message: 'No user found');
      }

      if (!(userDoc.data()?['otpVerified'] ?? false)) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'otp-unverified', message: 'OTP not verified');
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw FirebaseAuthException(code: 'login-failed', message: 'Login failed');
    }
  }

  /// ✅ Check Admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && userDoc['userType'] == 'admin';
  }

  /// ✅ Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ✅ Centralized Firebase Error Handler
  FirebaseAuthException _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return FirebaseAuthException(code: e.code, message: 'Email already in use');
      case 'invalid-email':
        return FirebaseAuthException(code: e.code, message: 'Invalid email');
      case 'weak-password':
        return FirebaseAuthException(code: e.code, message: 'Weak password');
      case 'user-not-found':
        return FirebaseAuthException(code: e.code, message: 'User not found');
      case 'wrong-password':
        return FirebaseAuthException(code: e.code, message: 'Wrong password');
      case 'user-disabled':
        return FirebaseAuthException(code: e.code, message: 'Account disabled');
      default:
        return FirebaseAuthException(code: e.code, message: e.message ?? 'Unknown error');
    }
  }

  /// ✅ Get User Data
  Future<DocumentSnapshot> getUserData(String uid, bool isTrader) async {
    return _firestore.collection(isTrader ? 'traders' : 'users').doc(uid).get();
  }
}
