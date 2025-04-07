// admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'package:multi_vendor_cloud_resturent_system/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _restaurants = [];
  List<DocumentSnapshot> _pendingApprovals = [];
  List<DocumentSnapshot> _restaurantMenu = [];
  List<DocumentSnapshot> _recentActivities = [];

  bool _isLoading = true;
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _loadRestaurants(),
        _loadPendingApprovals(),
        _loadRecentActivities(),
      ]);
    } catch (e) {
      print("LoadAllData Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .where('approved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();
      _restaurants = snapshot.docs;
    } catch (e) {
      print("LoadRestaurants Error: $e");
    }
  }

  Future<void> _loadPendingApprovals() async {
    try {
      final snapshot = await _firestore
          .collection('traders')
          .where('isApproved', isEqualTo: false)
          .get();
      setState(() => _pendingApprovals = snapshot.docs);
    } catch (e) {
      print("LoadPendingApprovals Error: $e");
    }
  }

  Future<void> _loadRestaurantMenu(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() => _restaurantMenu = snapshot.docs);
    } catch (e) {
      print("LoadRestaurantMenu Error: $e");
    }
  }

  Future<void> _loadRecentActivities() async {
  try {
    final approvals = await _firestore
        .collection('restaurants')
        .where('approved', isEqualTo: true)
        .orderBy('approvedAt', descending: true)
        .limit(3)
        .get();

    final orders = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    final all = [...approvals.docs, ...orders.docs];

    all.sort((a, b) {
      final Timestamp aTime =
          (a.data() as Map<String, dynamic>?)?['approvedAt'] ??
          (a.data() as Map<String, dynamic>?)?['createdAt'] ??
          Timestamp(0, 0);
      final Timestamp bTime =
          (b.data() as Map<String, dynamic>?)?['approvedAt'] ??
          (b.data() as Map<String, dynamic>?)?['createdAt'] ??
          Timestamp(0, 0);
      return bTime.compareTo(aTime);
    });

    setState(() => _recentActivities = all);
  } catch (e) {
    print("LoadRecentActivities Error: $e");
  }
}


  Future<void> _approveTrader(String id) async {
    try {
      await _firestore.collection('traders').doc(id).update({
        'isApproved': true,
      });
      await _loadPendingApprovals();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trader approved successfully')),
      );
    } catch (e) {
      print("ApproveTrader Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving trader')),
      );
    }
  }

  Future<void> _deleteMenuItem(String restaurantId, String itemId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .delete();
      await _loadRestaurantMenu(restaurantId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item deleted')),
      );
    } catch (e) {
      print("DeleteMenuItem Error: $e");
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('MMM d, y • h:mm a').format(timestamp.toDate());
  }

  int _calculateTotalMenuItems() {
    return _restaurantMenu.length;
  }

  Future<void> _showDeleteMenuItemDialog(String restaurantId, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Menu Item"),
        content: Text("Are you sure you want to delete this menu item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await _deleteMenuItem(restaurantId, itemId);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildRestaurantsTab();
      case 2:
        return _buildApprovalsTab();
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAllData();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Restaurants"),
          BottomNavigationBarItem(icon: Icon(Icons.approval), label: "Approvals"),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard("Total Restaurants", _restaurants.length.toString(), Icons.restaurant, Colors.blue),
              _buildStatCard("Pending Traders", _pendingApprovals.length.toString(), Icons.pending, Colors.orange),
              _buildStatCard("Total Menu Items", _calculateTotalMenuItems().toString(), Icons.menu_book, Colors.purple),
              _buildStatCard("Active Traders", _restaurants.length.toString(), Icons.people, Colors.green),
            ],
          ),
         SizedBox(height: 24),
Text("Recent Activities", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
SizedBox(height: 12),
_recentActivities.isEmpty
    ? Text("No recent activity found.")
    : Column(
        children: _recentActivities.map((doc) {
          final data = (doc.data() as Map<String, dynamic>?) ?? {};
          final isOrder = data.containsKey('items');
          final timestamp = data['createdAt'] ?? data['approvedAt'];

          return ListTile(
            leading: Icon(
              isOrder ? Icons.shopping_bag : Icons.restaurant,
              color: isOrder ? Colors.green : Colors.blue,
            ),
            title: Text(
              isOrder
                  ? "Order #${doc.id.substring(0, 6)}"
                  : "Approved: ${data['name'] ?? 'Unnamed Restaurant'}",
            ),
            subtitle: Text(_formatTimestamp(timestamp)),
          );
        }).toList(),
      )

        ],
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return ListView.builder(
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final doc = _restaurants[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return ExpansionTile(
          title: Text(data['name'] ?? 'Unnamed'),
          subtitle: Text(data['address'] ?? ''),
          onExpansionChanged: (expanded) {
            if (expanded) {
              _selectedRestaurantId = doc.id;
              _loadRestaurantMenu(doc.id);
            }
          },
          children: _restaurantMenu.map((item) {
            final itemData = (item.data() as Map<String, dynamic>?) ?? {};
            return ListTile(
              title: Text(itemData['name'] ?? ''),
              subtitle: Text("\$${itemData['price']}"),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteMenuItemDialog(doc.id, item.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildApprovalsTab() {
    return ListView.builder(
      itemCount: _pendingApprovals.length,
      itemBuilder: (context, index) {
        final doc = _pendingApprovals[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return Card(
          margin: EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['businessName'] ?? 'Unnamed Business',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Address: ${data['address'] ?? 'N/A'}"),
                Text("Phone: ${data['phone'] ?? 'N/A'}"),
                Text("Email: ${data['email'] ?? 'N/A'}"),
                Text("User Type: ${data['userType'] ?? 'N/A'}"),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      label: Text("Approve"),
                      onPressed: () => _approveTrader(doc.id),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
