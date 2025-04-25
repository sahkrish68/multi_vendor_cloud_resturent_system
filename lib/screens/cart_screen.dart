import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';
import '../screens/order_confirmation_screen.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _firebaseAuth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: userId == null
          ? _buildGuestView()
          : _buildCartItems(userId),
      bottomNavigationBar: _buildCheckoutBar(userId),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Please sign in to view your cart'),
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

  Widget _buildCartItems(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').doc(userId).collection('cart').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Your cart is empty'),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Browse restaurants'),
                ),
              ],
            ),
          );
        }

        final cartItems = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            var item = cartItems[index].data() as Map<String, dynamic>;
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
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, size: 18),
                                      onPressed: () => _updateItemQuantity(
                                          userId, cartItems[index].id, -1),
                                    ),
                                    Text('${item['quantity'] ?? 1}'),
                                    IconButton(
                                      icon: Icon(Icons.add, size: 18),
                                      onPressed: () => _updateItemQuantity(
                                          userId, cartItems[index].id, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckoutBar(String? userId) {
  if (userId == null) return SizedBox.shrink();

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!)),
    ),
    child: Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total', style: TextStyle(color: Colors.grey)),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(userId).collection('cart').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Text('\$0.00');

                double total = 0;
                for (var doc in snapshot.data!.docs) {
                  final item = doc.data() as Map<String, dynamic>;
                  total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
                }

                return Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
        Spacer(),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
               builder: (context) => CheckoutScreen(),
              ),
            );
          },
          child: Text('Checkout'),
        ),
      ],
    ),
  );
}

  Future<void> _updateItemQuantity(String userId, String itemId, int change) async {
    final itemRef = _firestore.collection('users').doc(userId).collection('cart').doc(itemId);
    final doc = await itemRef.get();

    if (doc.exists) {
      final currentQty = doc['quantity'] ?? 1;
      final newQty = currentQty + change;

      if (newQty <= 0) {
        await itemRef.delete();
      } else {
        await itemRef.update({'quantity': newQty});
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
