import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'trader_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool isTrader = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      User? user = await _auth.login(email, password, isTrader: isTrader);

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection(isTrader ? 'traders' : 'users')
            .doc(user.uid)
            .get();

        if (isTrader) {
          if (userDoc.exists && userDoc['isApproved'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TraderHomeScreen()),
            );
          } else {
            await _auth.signOut();
            setState(() => _errorMessage = 'Account pending admin approval');
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        setState(() => _errorMessage = 'Invalid email or password');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Login failed: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 20),
              Text(
                isTrader ? 'Trader Login' : 'User Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              SwitchListTile(
                title: Text('Login as Trader'),
                value: isTrader,
                onChanged: isLoading ? null : (value) => setState(() => isTrader = value),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty ? 'Enter your email' : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (val) => val!.length < 6 ? 'Minimum 6 characters' : null,
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                child: isLoading 
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text('LOGIN'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              TextButton(
                onPressed: isLoading 
                    ? null 
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        ),
                child: Text('Create new account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}