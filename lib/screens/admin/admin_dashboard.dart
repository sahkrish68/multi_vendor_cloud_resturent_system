import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'package:multi_vendor_cloud_resturent_system/screens/login_screen.dart';
import 'package:multi_vendor_cloud_resturent_system/screens/admin/order_details_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  List<DocumentSnapshot> _restaurants = [];
  List<DocumentSnapshot> _pendingApprovals = [];
  Map<String, List<DocumentSnapshot>> _restaurantMenus = {};
  Map<String, double> _restaurantSales = {};
  List<DocumentSnapshot> _recentActivities = [];

  bool _isLoading = true;
  String _searchQuery = '';

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
      final snapshot = await _firestore.collection('restaurants').orderBy('name').get();
      _restaurants = snapshot.docs;

      for (var doc in _restaurants) {
        await _loadRestaurantMenu(doc.id);
        await _loadRestaurantSales(doc.id);
      }
    } catch (e) {
      print("LoadRestaurants Error: $e");
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
      _restaurantMenus[restaurantId] = snapshot.docs;
    } catch (e) {
      print("LoadRestaurantMenu Error: $e");
    }
  }

  Future<void> _loadRestaurantSales(String restaurantId) async {
    try {
      final orderSnapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      double totalSales = 0;
      for (var doc in orderSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        totalSales += (data?['totalAmount'] ?? 0).toDouble();
      }

      _restaurantSales[restaurantId] = totalSales;
    } catch (e) {
      print("LoadRestaurantSales Error: $e");
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

  Future<void> _loadRecentActivities() async {
    try {
      final snapshot = await _firestore.collection('restaurants').orderBy('name').get();
      final orders = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      final all = [...snapshot.docs, ...orders.docs];

      all.sort((a, b) {
        final Timestamp aTime = (a.data() as Map<String, dynamic>?)?['approvedAt'] ??
            (a.data() as Map<String, dynamic>?)?['createdAt'] ??
            Timestamp(0, 0);
        final Timestamp bTime = (b.data() as Map<String, dynamic>?)?['approvedAt'] ??
            (b.data() as Map<String, dynamic>?)?['createdAt'] ??
            Timestamp(0, 0);
        return bTime.compareTo(aTime);
      });

      setState(() => _recentActivities = all.cast<DocumentSnapshot>());
    } catch (e) {
      print("LoadRecentActivities Error: $e");
    }
  }

  Future<void> _approveTrader(String id) async {
    try {
      await _firestore.collection('traders').doc(id).update({'isApproved': true});

      final restaurantSnap = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: id)
          .get();

      for (var doc in restaurantSnap.docs) {
        await doc.reference.update({
          'approved': true,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      await _loadPendingApprovals();
      await _loadRestaurants();

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

  Future<void> _declineTrader(String id) async {
    try {
      await _firestore.collection('traders').doc(id).delete();
      await _loadPendingApprovals();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trader declined and removed')),
      );
    } catch (e) {
      print("DeclineTrader Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining trader')),
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
    return _restaurantMenus.values.fold(0, (sum, items) => sum + items.length);
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
  Future<void> _showOrderDetailsDialog(String orderId) async {
  try {
    final doc = await _firestore.collection('orders').doc(orderId).get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order not found')));
      return;
    }

    final data = doc.data() as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Order ID: $orderId"),
              SizedBox(height: 8),
              Text("Customer: ${data['customerName'] ?? 'Unknown'}"),
              Text("Restaurant: ${data['restaurantName'] ?? 'Unknown'}"),
              Text("Payment Method: ${data['paymentMethod'] ?? 'Unknown'}"),
              SizedBox(height: 12),
              Text("Items Ordered:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...((data['items'] as List<dynamic>? ?? []).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("- ${item['name']} x${item['quantity']}"),
                );
              }).toList()),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  } catch (e) {
    print("ShowOrderDetailsDialog Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load order details')));
  }
}


  Widget _buildRestaurantsTab() {
    return ListView.builder(
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final doc = _restaurants[index];
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final restaurantId = doc.id;
        final menuItems = _restaurantMenus[restaurantId] ?? [];

        return ExpansionTile(
          title: Row(
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Unnamed',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(data['address'] ?? '', style: TextStyle(color: Colors.grey)),
                    Text(
                      "Sales: \$${_restaurantSales[restaurantId]?.toStringAsFixed(2) ?? '0.00'}",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: menuItems.map((item) {
            final itemData = item.data() as Map<String, dynamic>? ?? {};
            final category = itemData['category'] ?? 'Uncategorized';
            return ListTile(
              title: Text(itemData['name'] ?? ''),
              subtitle: Text("Category: $category"),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteMenuItemDialog(restaurantId, item.id),
              ),
            );
          }).toList(),
        );
      },
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
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by Order Number...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
        ),
        SizedBox(height: 12),
        Text("Recent Activities", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        _recentActivities.isEmpty
            ? Text("No recent activity found.")
            : Column(
                children: _recentActivities.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final isOrder = data.containsKey('items');
                  if (!isOrder) return true;
                  return doc.id.toLowerCase().contains(_searchQuery.toLowerCase());
                }).map((doc) {
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
                    onTap: () {
                      if (isOrder) {
                        _showOrderDetailsDialog(doc.id);
                      }
                    },
                  );
                }).toList(),
              ),
      ],
    ),
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
                      icon: Icon(Icons.close),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      label: Text("Decline"),
                      onPressed: () => _declineTrader(doc.id),
                    ),
                    SizedBox(width: 10),
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
}
