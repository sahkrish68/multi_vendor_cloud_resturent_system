import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User login
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Trader login
  Future<User?> loginTrader(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // User registration
  Future<User?> registerUser(
      String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Store additional user info in Firestore
      await _firestore.collection('users').doc(user?.uid).set({
        'uid': user?.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'userType': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Trader registration
  Future<User?> registerTrader(
      String email,
      String password,
      String businessName,
      String phone,
      String address,
      String businessType) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Store additional trader info in Firestore
      await _firestore.collection('traders').doc(user?.uid).set({
        'uid': user?.uid,
        'email': email,
        'businessName': businessName,
        'phone': phone,
        'address': address,
        'businessType': businessType,
        'userType': 'trader',
        'isApproved': false, // Admin needs to approve
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}