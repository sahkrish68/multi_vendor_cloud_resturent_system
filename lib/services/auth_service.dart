import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Generate and store OTP, then send it to email
 Future<void> sendOtpToEmail(String email) async {
  try {
    final otp = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;

    print("User UID: ${FirebaseAuth.instance.currentUser?.uid}");

    await _firestore.collection('emailOtps').doc(email).set({
      'otp': otp,
      'expiresAt': expiresAt,
    });

    print("✅ OTP stored in Firestore");

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost', // Required by EmailJS
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
      print("❌ EmailJS failed: ${response.body}");
      throw Exception("Failed to send OTP email");
    }

    print("✅ OTP email sent via EmailJS to $email");
  } catch (e) {
    print("❌ sendOtpToEmail failed: $e");
    rethrow;
  }
 }
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print("📥 Creating user with email: $email");

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("✅ User created: ${result.user?.uid}");

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
    } catch (e) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed. Please try again',
      );
    }
  }

  Future<User?> registerTrader({
    required String email,
    required String password,
    required String businessName,
    required String phone,
    required String address,
    required String businessType,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
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
    } catch (e) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Trader registration failed. Please try again',
      );
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final doc = await _firestore.collection('emailOtps').doc(email).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'];
    final expiresAt = data['expiresAt'];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now > expiresAt || storedOtp != otp) return false;

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

  Future<User?> login(String email, String password, {bool isTrader = false}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userDoc = await _firestore
          .collection(isTrader ? 'traders' : 'users')
          .doc(result.user?.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-mismatch',
          message: 'No ${isTrader ? 'trader' : 'user'} found with these credentials',
        );
      }

      if (!(userDoc.data()?['otpVerified'] ?? false)) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'otp-unverified',
          message: 'Please verify your email OTP before logging in',
        );
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed. Please try again',
      );
    }
  }

  Future<bool> isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && userDoc['userType'] == 'admin';
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw FirebaseAuthException(
        code: 'logout-failed',
        message: 'Failed to sign out. Please try again',
      );
    }
  }

  FirebaseAuthException _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return FirebaseAuthException(code: e.code, message: 'This email is already registered');
      case 'invalid-email':
        return FirebaseAuthException(code: e.code, message: 'Please enter a valid email address');
      case 'weak-password':
        return FirebaseAuthException(code: e.code, message: 'Password should be at least 6 characters');
      case 'user-not-found':
        return FirebaseAuthException(code: e.code, message: 'No user found with this email');
      case 'wrong-password':
        return FirebaseAuthException(code: e.code, message: 'Incorrect password');
      case 'user-disabled':
        return FirebaseAuthException(code: e.code, message: 'This account has been disabled');
      case 'user-mismatch':
        return e;
      default:
        return FirebaseAuthException(code: e.code, message: 'Authentication error: ${e.message}');
    }
  }

  Future<DocumentSnapshot> getUserData(String uid, bool isTrader) async {
    return await _firestore.collection(isTrader ? 'traders' : 'users').doc(uid).get();
  }
}
