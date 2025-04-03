import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'order_confirmation_screen.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _auth = AuthService();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userId = _firebaseAuth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: userId == null
          ? _buildGuestView()
          : _buildCheckoutDetails(userId),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Please sign in to proceed with checkout'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutDetails(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').doc(userId).collection('cart').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Your cart is empty'));
        }

        final cartItems = snapshot.data!.docs;

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Cart item details
            ...cartItems.map((doc) {
              var item = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item['imageUrl'] != null
                            ? Image.network(
                                item['imageUrl'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(Icons.fastfood),
                              ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'No Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(item['restaurantName'] ?? ''),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Spacer(),
                                Text('x${item['quantity'] ?? 1}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            Divider(),

            // Shipping Address
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter your shipping address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Payment Method Options
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Credit Card'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('PayPal'),
                ),
              ],
            ),

            Divider(),

            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Total: \$${_calculateTotal(cartItems)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),

            // Place Order Button
            ElevatedButton(
              onPressed: () {
                // Handle checkout
                _handleCheckout(userId);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
              ),
              child: Text('Place Order'),
            ),
          ],
        );
      },
    );
  }

  double _calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    double total = 0;
    for (var doc in cartItems) {
      final item = doc.data() as Map<String, dynamic>;
      total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
    }
    return total;
  }

  void _handleCheckout(String userId) {
    final shippingAddress = _addressController.text;
    if (shippingAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a shipping address')));
      return;
    }

    // Here you would send the order to Firestore, and initiate payment (e.g., via PayPal or Credit Card)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processing your order...')));
    // For now, navigate to the OrderConfirmationScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderConfirmationScreen()),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
