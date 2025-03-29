import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'restaurant_detail_screen.dart';

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
      bottomNavigationBar: _buildCheckoutBar(),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        List<dynamic> cartItems = userData['cart'] ?? [];

        if (cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Your cart is empty'),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Browse restaurants'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            var item = cartItems[index] as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['imageUrl'] ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(width: 80, height: 80, color: Colors.grey[200]),
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
                                        userId, 
                                        item['id'], 
                                        -1,
                                      ),
                                    ),
                                    Text(item['quantity'].toString()),
                                    IconButton(
                                      icon: Icon(Icons.add, size: 18),
                                      onPressed: () => _updateItemQuantity(
                                        userId, 
                                        item['id'], 
                                        1,
                                      ),
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

  Widget _buildCheckoutBar() {
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
              Text(
                'Total',
                style: TextStyle(color: Colors.grey),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(_firebaseAuth.currentUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('\$0.00');
                  
                  var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  List<dynamic> cartItems = userData['cart'] ?? [];
                  
                  double total = 0;
                  for (var item in cartItems) {
                    total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
                  }
                  
                  return Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,  // Changed from 'primary' to 'backgroundColor'
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Checkout functionality will be implemented here')),
              );
            },
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItemQuantity(String userId, String itemId, int change) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();
      
      List<dynamic> cartItems = doc.data()?['cart'] ?? [];
      int itemIndex = cartItems.indexWhere((item) => item['id'] == itemId);
      
      if (itemIndex != -1) {
        int newQuantity = (cartItems[itemIndex]['quantity'] ?? 1) + change;
        
        if (newQuantity <= 0) {
          cartItems.removeAt(itemIndex);
        } else {
          cartItems[itemIndex]['quantity'] = newQuantity;
        }
        
        await userRef.update({'cart': cartItems});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e')),
      );
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