import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'trader_home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool isTrader = false;
  bool isLoading = false;

  // User fields
  String userName = '';
  String userPhone = '';

  // Trader fields
  String businessName = '';
  String traderPhone = '';
  String address = '';
  String businessType = 'restaurant'; // Default value

  // Common fields
  String email = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
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
                  isTrader ? 'Trader Registration' : 'User Registration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                SwitchListTile(
                  title: Text('Register as Trader'),
                  value: isTrader,
                  onChanged: (bool value) {
                    setState(() {
                      isTrader = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                // Common fields
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
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) =>
                      val != password ? 'Passwords do not match' : null,
                  onChanged: (val) {
                    setState(() => confirmPassword = val);
                  },
                ),
                SizedBox(height: 20),
                
                // User specific fields
                if (!isTrader) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter your name' : null,
                    onChanged: (val) {
                      setState(() => userName = val);
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter your phone number' : null,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) {
                      setState(() => userPhone = val);
                    },
                  ),
                ],
                
                // Trader specific fields
                if (isTrader) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter business name' : null,
                    onChanged: (val) {
                      setState(() => businessName = val);
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter phone number' : null,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) {
                      setState(() => traderPhone = val);
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter business address' : null,
                    onChanged: (val) {
                      setState(() => address = val);
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'Business Type',
                      border: OutlineInputBorder(),
                    ),
                    value: businessType,
                    items: ['restaurant', 'cloud kitchen', 'cafe', 'bakery']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.capitalize()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => businessType = val.toString());
                    },
                  ),
                ],
                
                SizedBox(height: 30),
                ElevatedButton(
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      User? user;
                      
                      if (isTrader) {
                        user = await _auth.registerTrader(
                          email,
                          password,
                          businessName,
                          traderPhone,
                          address,
                          businessType,
                        );
                      } else {
                        user = await _auth.registerUser(
                          email,
                          password,
                          userName,
                          userPhone,
                        );
                      }
                      
                      setState(() => isLoading = false);
                      
                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isTrader
                                ? TraderHomeScreen()
                                : HomeScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration failed'),
                          ),
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: 10),
                TextButton(
                  child: Text('Already have an account? Login here'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}