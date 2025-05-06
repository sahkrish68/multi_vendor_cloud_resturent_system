import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: OrderHistoryScreen()));
}

class OrderHistoryScreen extends StatelessWidget {
  // 🔥 Delete order from global orders collection
  Future<void> deleteOrder(BuildContext context, String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final Query userOrdersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: userOrdersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong 😓'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('You have no orders yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final orderId = docs[index].id;
              final restaurantName = data['restaurantName'] ?? 'Unknown Restaurant';
              final status = data['status'] ?? 'Unknown Status';
              final totalAmount = data['total'] ?? data['amount'] ?? 0;

              String orderDate = 'Unknown Date';
              if (data['createdAt'] != null) {
                DateTime dateTime;
                if (data['createdAt'] is Timestamp) {
                  dateTime = (data['createdAt'] as Timestamp).toDate();
                } else {
                  dateTime = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
                }
                orderDate = DateFormat('yMMMd • hh:mm a').format(dateTime);
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  isThreeLine: true,
                  leading: Icon(Icons.receipt_long, color: Colors.brown),
                  title: Text(
                    '$restaurantName • ₹$totalAmount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Status: $status\nOrdered: $orderDate',
                    style: TextStyle(height: 1.3),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete Order'),
                          content: Text('Are you sure you want to delete this order?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                deleteOrder(context, orderId);
                              },
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
