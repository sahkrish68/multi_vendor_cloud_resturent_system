import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'order_confirmation_screen.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

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
        final total = _calculateTotal(cartItems);

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...cartItems.map((doc) => _buildCartItem(doc)).toList(),
              Divider(),
              _buildShippingSection(),
              _buildPaymentSection(),
              Divider(),
              _buildTotalSection(total),
              _buildPlaceOrderButton(userId, cartItems),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(QueryDocumentSnapshot doc) {
    final item = doc.data() as Map<String, dynamic>;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item['imageUrl'] != null
            ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
            : Icon(Icons.fastfood, size: 50),
        title: Text(item['name'] ?? 'Item'),
        subtitle: Text(item['restaurantName'] ?? ''),
        trailing: Text('\$${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(2)}'),
      ),
    );
  }

  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Enter delivery address',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('Cash on Delivery'),
              selected: _selectedPaymentMethod == 'cod',
              onSelected: (selected) {
                setState(() => _selectedPaymentMethod = selected ? 'cod' : null);
              },
            ),
            ChoiceChip(
              label: Text('Credit Card'),
              selected: _selectedPaymentMethod == 'credit',
              onSelected: (selected) {
                setState(() => _selectedPaymentMethod = selected ? 'credit' : null);
              },
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTotalSection(double total) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total:', style: TextStyle(fontSize: 18)),
          Text('\$${total.toStringAsFixed(2)}', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(String userId, List<QueryDocumentSnapshot> cartItems) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleCheckout(userId, cartItems),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange,
        ),
        child: _isProcessing
            ? CircularProgressIndicator(color: Colors.white)
            : Text('PLACE ORDER', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  double _calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    return cartItems.fold(0, (sum, doc) {
      final item = doc.data() as Map<String, dynamic>;
      return sum + (item['price'] ?? 0) * (item['quantity'] ?? 1);
    });
  }

  Future<void> _handleCheckout(String userId, List<QueryDocumentSnapshot> cartItems) async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a shipping address')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Prepare order data
      final orderId = _firestore.collection('orders').doc().id;
      final now = Timestamp.now();
      final restaurantId = cartItems.first['restaurantId'];
      final restaurantName = cartItems.first['restaurantName'] ?? 'Restaurant';
      final total = _calculateTotal(cartItems);

      // Create order document
      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'restaurantId': restaurantId,
        'customer': {
          'name': userData['name'] ?? 'Customer',
          'email': userData['email'],
          'phone': userData['phone'] ?? '',
        },
        'restaurantName': restaurantName,
        'shippingAddress': _addressController.text,
        'paymentMethod': _selectedPaymentMethod,
        'items': cartItems.map((doc) {
          final item = doc.data() as Map<String, dynamic>;
          return {
            'id': item['id'],
            'name': item['name'],
            'price': item['price'],
            'quantity': item['quantity'],
            'imageUrl': item['imageUrl'],
          };
        }).toList(),
        'total': total,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      };

      // Batch write to multiple collections
      final batch = _firestore.batch();

      // 1. Main orders collection
      batch.set(_firestore.collection('orders').doc(orderId), orderData);

      // 2. User's orders subcollection
      batch.set(
        _firestore.collection('users').doc(userId).collection('orders').doc(orderId),
        {
          'orderId': orderId,
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'total': total,
          'status': 'pending',
          'createdAt': now,
        },
      );

      // 3. Restaurant's orders subcollection
      batch.set(
        _firestore.collection('restaurants').doc(restaurantId).collection('orders').doc(orderId),
        {
          'orderId': orderId,
          'userId': userId,
          'customerName': userData['name'] ?? 'Customer',
          'total': total,
          'status': 'pending',
          'createdAt': now,
        },
      );

      // 4. Clear cart
      for (var item in cartItems) {
        batch.delete(item.reference);
      }

      await batch.commit();

      // Navigate to confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: orderId),
        ),
      );

    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: ${e.toString()}')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}