// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';


// class TraderManagementScreen extends StatefulWidget {
//   @override
//   _TraderManagementScreenState createState() => _TraderManagementScreenState();
// }

// class _TraderManagementScreenState extends State<TraderManagementScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String _filter = 'all'; // 'all', 'approved', 'pending'

//   Future<void> _approveTrader(String traderId) async {
//     await _firestore.collection('traders').doc(traderId).update({'isApproved': true});
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trader approved')));
//   }

//   Future<void> _deleteTrader(String traderId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Delete Trader'),
//         content: Text('Are you sure you want to delete this trader?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await _firestore.collection('traders').doc(traderId).delete();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trader deleted')));
//     }
//   }

//   Stream<QuerySnapshot> _getTraderStream() {
//     var query = _firestore.collection('traders');
//     if (_filter == 'approved') {
//       query = query.where('isApproved', isEqualTo: true);
//     } else if (_filter == 'pending') {
//       query = query.where('isApproved', isEqualTo: false);
//     }
//     return query.snapshots();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Manage Traders'),
//         actions: [
//           PopupMenuButton<String>(
//             icon: Icon(Icons.filter_list),
//             onSelected: (value) => setState(() => _filter = value),
//             itemBuilder: (context) => [
//               PopupMenuItem(value: 'all', child: Text('All')),
//               PopupMenuItem(value: 'approved', child: Text('Approved')),
//               PopupMenuItem(value: 'pending', child: Text('Pending')),
//             ],
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _getTraderStream(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) return Center(child: Text('Error loading traders'));
//           if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

//           final traders = snapshot.data!.docs;
//           if (traders.isEmpty) return Center(child: Text('No traders found'));

//           return ListView.builder(
//             itemCount: traders.length,
//             itemBuilder: (context, index) {
//               final data = traders[index].data() as Map<String, dynamic>;
//               final id = traders[index].id;
//               final name = data['businessName'] ?? 'Unnamed';
//               final email = data['email'] ?? 'No email';
//               final isApproved = data['isApproved'] == true;

//               return ListTile(
//                 title: Text(name),
//                 subtitle: Text(email),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (!isApproved)
//                       IconButton(
//                         icon: Icon(Icons.check_circle, color: Colors.green),
//                         onPressed: () => _approveTrader(id),
//                       ),
//                     IconButton(
//                       icon: Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _deleteTrader(id),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
