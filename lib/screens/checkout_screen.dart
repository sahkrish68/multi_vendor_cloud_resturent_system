import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'order_confirmation_screen.dart';
import 'paypal_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _paymentMethod;
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Center(child: Text("Please login."));

    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final cartItems = snapshot.data!.docs;
          if (cartItems.isEmpty) return Center(child: Text("Your cart is empty"));

          final items = cartItems.map((doc) => doc.data() as Map<String, dynamic>).toList();
          final total = items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  "Delivery Address",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "Enter delivery address",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 24),
                Text(
                  "Payment Method",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: Text('Cash on Delivery'),
                      selected: _paymentMethod == 'cod',
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setState(() => _paymentMethod = 'cod'),
                    ),
                    ChoiceChip(
                      label: Text('Credit Card (PayPal)'),
                      selected: _paymentMethod == 'credit',
                      selectedColor: Colors.blue.shade100,
                      onSelected: (_) => setState(() => _paymentMethod = 'credit'),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Divider(),
                ListTile(
                  title: Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  trailing: Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Divider(),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: _isPlacingOrder
                        ? null
                        : () async {
                            if (_addressController.text.isEmpty || _paymentMethod == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }

                            setState(() => _isPlacingOrder = true);

                            final restaurantId = items.first['restaurantId'];
                            final restaurantName = items.first['restaurantName'] ?? 'Restaurant';

                            try {
                              // ✅ If PayPal selected, first complete payment
                              if (_paymentMethod == 'credit') {
                                bool paymentSuccess = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PayPalPaymentScreen(
                                      totalAmount: total,
                                      onFinish: (success) {
                                        Navigator.pop(context, success);
                                      },
                                    ),
                                  ),
                                );

                                if (!paymentSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Payment cancelled or failed')),
                                  );
                                  setState(() => _isPlacingOrder = false);
                                  return;
                                }
                              }

                              // ✅ Then create order
                              final orderId = await _authService.createOrder(
                                userId: uid,
                                restaurantId: restaurantId,
                                restaurantName: restaurantName,
                                address: _addressController.text,
                                paymentMethod: _paymentMethod!,
                                items: cartItems.map((doc) => doc.data() as Map<String, dynamic>).toList(),
                                total: total,
                              );
                              // ✅ Send order confirmation email
                                final userEmail = FirebaseAuth.instance.currentUser?.email;
                                if (userEmail != null) {
                                  await _authService.sendOrderConfirmationEmail(
                                    toEmail: userEmail,
                                    orderId: orderId,
                                    restaurantName: restaurantName,
                                    total: total,
                                );
                                }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order placed successfully!')),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderConfirmationScreen(orderId: orderId),
                                ),
                              );
                            } catch (e) {
                              print("CreateOrder Error: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to place order')),
                              );
                            } finally {
                              setState(() => _isPlacingOrder = false);
                            }
                          },
                    child: _isPlacingOrder
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Place Order'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
