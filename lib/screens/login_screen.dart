import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'trader_home_screen.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool isTrader = false;
  bool isLoading = false;

  // Text field state
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  isTrader ? 'Trader Login' : 'User Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                SwitchListTile(
                  title: Text('Login as Trader'),
                  value: isTrader,
                  onChanged: (bool value) {
                    setState(() {
                      isTrader = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      User? user;
                      if (isTrader) {
                        user = await _auth.loginTrader(email, password);
                      } else {
                        user = await _auth.loginUser(email, password);
                      }
                      setState(() => isLoading = false);
                      
                      if (user != null) {
                        // Check user type in Firestore
                        DocumentSnapshot userDoc = isTrader
                            ? await FirebaseFirestore.instance
                                .collection('traders')
                                .doc(user.uid)
                                .get()
                            : await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                                
                        if (isTrader) {
                          if (userDoc['isApproved']) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TraderHomeScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Your account is pending approval from admin'),
                              ),
                            );
                            await _auth.signOut();
                          }
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid credentials'),
                          ),
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: 10),
                TextButton(
                  child: Text('Don\'t have an account? Register here'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}