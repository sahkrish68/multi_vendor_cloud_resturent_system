import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';  // ✅ Adjust if path is different


class CheckoutScreen extends StatefulWidget {
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  final AuthService _authService = AuthService();
   String? _selectedPaymentMethod;
   String? _paymentMethod;
   bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Center(child: Text("Please login."));

    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final cartItems = snapshot.data!.docs;
          if (cartItems.isEmpty) return Center(child: Text("Your cart is empty"));

          final items = cartItems.map((doc) => doc.data() as Map<String, dynamic>).toList();
          final total = items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: "Delivery Address"),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Cash on Delivery'),
                      selected: _paymentMethod == 'cod',
                      onSelected: (_) => setState(() => _paymentMethod = 'cod'),
                    ),
                    SizedBox(width: 10),
                    ChoiceChip(
                      label: Text('Credit Card'),
                      selected: _paymentMethod == 'credit',
                      onSelected: (_) => setState(() => _paymentMethod = 'credit'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isPlacingOrder
                      ? null
                      : () async {
                          if (_addressController.text.isEmpty || _paymentMethod == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Fill all fields')),
                            );
                            return;
                          }

                          setState(() => _isPlacingOrder = true);

                          // ✅ Example restaurant data
                          final restaurantId = items.first['restaurantId'];
                          final restaurantName = items.first['restaurantName'];

                          try {
                            await _authService.createOrder(
                              userId: FirebaseAuth.instance.currentUser!.uid,

                              restaurantId: restaurantId,
                              restaurantName: restaurantName,
                              address: _addressController.text,
                              paymentMethod: _paymentMethod!,
                              items: cartItems.map((doc) => doc.data() as Map<String, dynamic>).toList(),
                              total: total,
                            );
                            

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order placed!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to place order')),
                            );
                          } finally {
                            setState(() => _isPlacingOrder = false);
                          }
                        },
                  child: Text(_isPlacingOrder ? 'Placing Order...' : 'Place Order'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
