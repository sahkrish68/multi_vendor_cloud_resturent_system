import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists) {
            return Center(child: Text('Order not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order ID: $orderId", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Customer: ${data['customerName'] ?? 'Unknown'}"),
                Text("Restaurant: ${data['restaurantName'] ?? 'Unknown'}"),
                Text("Payment Method: ${data['paymentMethod'] ?? 'Unknown'}"),
                SizedBox(height: 20),
                Text("Order Items:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...((data['items'] as List<dynamic>? ?? []).map((item) {
                  return ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text("Quantity: ${item['quantity'] ?? 1}"),
                  );
                }).toList()),
              ],
            ),
          );
        },
      ),
    );
  }
}
