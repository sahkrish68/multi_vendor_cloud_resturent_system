import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) return Center(child: Text('No order history yet.'));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final createdAt = order['createdAt']?.toDate() ?? DateTime.now();
              return ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text(order['restaurantName'] ?? 'Unknown'),
                subtitle: Text(
                  '${DateFormat('MMM d, yyyy – h:mm a').format(createdAt)}\nStatus: ${order['status']}',
                ),
                trailing: Text('\$${order['total'].toStringAsFixed(2)}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
