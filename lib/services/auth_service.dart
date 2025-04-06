import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic login method that can handle both users and traders
  Future<User?> login(String email, String password, {bool isTrader = false}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Verify the user type matches what they're trying to login as
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

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Re-throw with more specific messages
      throw _handleAuthError(e);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed. Please try again',
      );
    }
  }

  // Register a regular user
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection('users').doc(result.user?.uid).set({
        'uid': result.user?.uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'userType': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

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

  // Register a trader
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
        'createdAt': FieldValue.serverTimestamp(),
      });

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
  Future<bool> isAdmin() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  return userDoc.exists && (userDoc['userType'] == 'admin');
}

  // Sign out
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

  // Helper method to handle auth errors
  FirebaseAuthException _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return FirebaseAuthException(
          code: e.code,
          message: 'This email is already registered',
        );
      case 'invalid-email':
        return FirebaseAuthException(
          code: e.code,
          message: 'Please enter a valid email address',
        );
      case 'weak-password':
        return FirebaseAuthException(
          code: e.code,
          message: 'Password should be at least 6 characters',
        );
      case 'user-not-found':
        return FirebaseAuthException(
          code: e.code,
          message: 'No user found with this email',
        );
      case 'wrong-password':
        return FirebaseAuthException(
          code: e.code,
          message: 'Incorrect password',
        );
      case 'user-disabled':
        return FirebaseAuthException(
          code: e.code,
          message: 'This account has been disabled',
        );
      case 'user-mismatch':
        return e; // Already has a good message
      default:
        return FirebaseAuthException(
          code: e.code,
          message: 'Authentication error: ${e.message}',
        );
    }
  }

  // Get current user's data
  Future<DocumentSnapshot> getUserData(String uid, bool isTrader) async {
    return await _firestore
        .collection(isTrader ? 'traders' : 'users')
        .doc(uid)
        .get();
  }
}