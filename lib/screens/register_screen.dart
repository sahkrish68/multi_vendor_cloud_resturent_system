import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessTypeController = TextEditingController();

  bool isTrader = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final phone = _phoneController.text.trim();
      User? user;

      if (isTrader) {
        final businessName = _businessNameController.text.trim();
        final address = _addressController.text.trim();
        final businessType = _businessTypeController.text.trim();

        user = await _auth.registerTrader(
          email: email,
          password: password,
          businessName: businessName,
          phone: phone,
          address: address,
          businessType: businessType,
        );
      } else {
        final name = _nameController.text.trim();
        user = await _auth.registerUser(
          email: email,
          password: password,
          name: name,
          phone: phone,
        );
      }

      if (user != null) {
        bool verified = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );

        if (verified == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP verified. You can now log in.')),
          );
        } else {
          await _auth.signOut();
          setState(() => _errorMessage = 'OTP verification required');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF2E6),
      appBar: AppBar(
        backgroundColor: Color(0xFF4A2C2A),
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                isTrader ? 'Trader Registration' : 'User Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C2A),
                ),
              ),
              SizedBox(height: 25),
              SwitchListTile(
                title: Text('Register as Trader', style: TextStyle(color: Color(0xFF4A2C2A))),
                value: isTrader,
                onChanged: isLoading ? null : (value) => setState(() => isTrader = value),
                activeColor: Color(0xFF4A2C2A),
              ),
              SizedBox(height: 15),
              if (!isTrader)
                _buildInputField(_nameController, 'Full Name', Icons.person),
              if (isTrader) ...[
                _buildInputField(_businessNameController, 'Business Name', Icons.store),
                SizedBox(height: 15),
                _buildInputField(_addressController, 'Business Address', Icons.location_on),
                SizedBox(height: 15),
                _buildInputField(_businessTypeController, 'Business Type', Icons.category),
              ],
              SizedBox(height: 15),
              _buildInputField(_phoneController, 'Phone Number', Icons.phone, keyboard: TextInputType.phone),
              SizedBox(height: 15),
              _buildInputField(_emailController, 'Email', Icons.email, keyboard: TextInputType.emailAddress),
              SizedBox(height: 15),
              _buildPasswordField(_passwordController, 'Password', _obscurePassword, () {
                setState(() => _obscurePassword = !_obscurePassword);
              }),
              SizedBox(height: 15),
              _buildPasswordField(_confirmPasswordController, 'Confirm Password', _obscureConfirmPassword, () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              }),
              SizedBox(height: 15),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('REGISTER'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF4A2C2A)),
        prefixIcon: Icon(icon, color: Color(0xFF4A2C2A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4A2C2A)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboard,
      validator: (val) => val!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF4A2C2A)),
        prefixIcon: Icon(Icons.lock, color: Color(0xFF4A2C2A)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Color(0xFF4A2C2A)),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4A2C2A)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (val) => val!.isEmpty ? 'Enter $label' : null,
    );
  }
}
