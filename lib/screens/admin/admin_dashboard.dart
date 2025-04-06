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
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  
  // State variables
  List<DocumentSnapshot> _restaurants = [];
  List<DocumentSnapshot> _pendingApprovals = [];
  bool _isLoading = true;
  String? _selectedRestaurantId;
  List<DocumentSnapshot> _restaurantMenu = [];
  List<DocumentSnapshot> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadRestaurants(),
      _loadPendingApprovals(),
      _loadRecentActivities(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('approved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();
      
      setState(() => _restaurants = snapshot.docs);
    } catch (e) {
      print("Error loading restaurants: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load restaurants')),
      );
    }
  }

  Future<void> _loadPendingApprovals() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('approved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      setState(() => _pendingApprovals = snapshot.docs);
    } catch (e) {
      print("Error loading pending approvals: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pending approvals')),
      );
    }
  }

  Future<void> _loadRestaurantMenu(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .orderBy('createdAt')
          .get();
      
      setState(() => _restaurantMenu = snapshot.docs);
    } catch (e) {
      print("Error loading restaurant menu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load menu items')),
      );
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      // Load recent restaurant approvals
      QuerySnapshot approvals = await _firestore
          .collection('restaurants')
          .where('approved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .limit(3)
          .get();

      // Load recent orders (if you have an orders collection)
      QuerySnapshot orders = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      setState(() {
        _recentActivities = [...approvals.docs, ...orders.docs];
        _recentActivities.sort((a, b) {
          var aTime = a['approvedAt'] ?? a['createdAt'];
          var bTime = b['approvedAt'] ?? b['createdAt'];
          return bTime.compareTo(aTime);
        });
      });
    } catch (e) {
      print("Error loading recent activities: $e");
    }
  }

  Future<void> _approveRestaurant(String restaurantId) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload data
      await Future.wait([_loadRestaurants(), _loadPendingApprovals(), _loadRecentActivities()]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving restaurant: $e')),
      );
    }
  }

  Future<void> _rejectRestaurant(String restaurantId) async {
    try {
      // First delete the restaurant's menu items
      QuerySnapshot menuItems = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .get();

      for (var doc in menuItems.docs) {
        await doc.reference.delete();
      }

      // Then delete the restaurant
      await _firestore.collection('restaurants').doc(restaurantId).delete();
      
      // Reload data
      await Future.wait([_loadRestaurants(), _loadPendingApprovals(), _loadRecentActivities()]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant rejected and removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting restaurant: $e')),
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
        SnackBar(content: Text('Menu item deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting menu item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.approval), label: 'Approvals'),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0: return _buildDashboardTab();
      case 1: return _buildRestaurantsTab();
      case 2: return _buildApprovalsTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Total Restaurants', _restaurants.length.toString(), Icons.restaurant, Colors.blue),
              _buildStatCard('Pending Approvals', _pendingApprovals.length.toString(), Icons.pending_actions, Colors.orange),
              _buildStatCard('Active Traders', _restaurants.length.toString(), Icons.people, Colors.green),
              _buildStatCard('Total Menu Items', _calculateTotalMenuItems().toString(), Icons.shopping_bag, Colors.purple),
            ],
          ),
          SizedBox(height: 24),
          Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: _recentActivities.isEmpty
                    ? [Text('No recent activities')]
                    : _recentActivities.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isOrder = data.containsKey('items');
                        
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isOrder ? Icons.shopping_bag : Icons.restaurant,
                                color: isOrder ? Colors.green : Colors.blue,
                              ),
                              title: Text(isOrder 
                                  ? 'New order #${doc.id.substring(0, 8)}' 
                                  : 'Approved ${data['name']}'),
                              subtitle: Text(_formatTimestamp(
                                isOrder ? data['createdAt'] : data['approvedAt'])),
                            ),
                            if (doc != _recentActivities.last) Divider(),
                          ],
                        );
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search restaurants',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  // Implement clear search functionality
                },
              ),
            ),
            onChanged: (value) {
              // Implement search functionality
              // You would filter _restaurants based on the search term
            },
          ),
        ),
        Expanded(
          child: _restaurants.isEmpty
              ? Center(child: Text('No approved restaurants yet'))
              : ListView.builder(
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    var restaurant = _restaurants[index];
                    var data = restaurant.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        leading: data['imageUrl']?.isNotEmpty ?? false
                            ? CircleAvatar(backgroundImage: NetworkImage(data['imageUrl']))
                            : CircleAvatar(child: Icon(Icons.restaurant)),
                        title: Text(data['name'] ?? 'Unnamed Restaurant'),
                        subtitle: Text(data['address'] ?? 'No address provided'),
                        onExpansionChanged: (expanded) {
                          if (expanded) {
                            setState(() => _selectedRestaurantId = restaurant.id);
                            _loadRestaurantMenu(restaurant.id);
                          }
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Restaurant Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text('Owner: ${data['ownerName'] ?? 'Not specified'}'),
                                Text('Phone: ${data['phone'] ?? 'Not provided'}'),
                                Text('Email: ${data['email'] ?? 'Not provided'}'),
                                SizedBox(height: 8),
                                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(data['description'] ?? 'No description provided'),
                                SizedBox(height: 16),
                                Text('Menu Items (${_restaurantMenu.length})', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                if (_restaurantMenu.isEmpty)
                                  Text('No menu items available')
                                else
                                  Column(
                                    children: _restaurantMenu.map((item) {
                                      var itemData = item.data() as Map<String, dynamic>;
                                      return ListTile(
                                        leading: itemData['imageUrl']?.isNotEmpty ?? false
                                            ? CircleAvatar(backgroundImage: NetworkImage(itemData['imageUrl']))
                                            : CircleAvatar(child: Icon(Icons.fastfood)),
                                        title: Text(itemData['name'] ?? 'Unnamed Item'),
                                        subtitle: Text('\$${itemData['price']?.toStringAsFixed(2) ?? '0.00'} • ${itemData['category'] ?? 'No category'}'),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteMenuItemDialog(restaurant.id, item.id),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildApprovalsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Pending Restaurant Approvals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _pendingApprovals.isEmpty
              ? Center(child: Text('No pending approvals'))
              : ListView.builder(
                  itemCount: _pendingApprovals.length,
                  itemBuilder: (context, index) {
                    var restaurant = _pendingApprovals[index];
                    var data = restaurant.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                data['imageUrl']?.isNotEmpty ?? false
                                    ? CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(data['imageUrl']),
                                      )
                                    : CircleAvatar(
                                        radius: 30,
                                        child: Icon(Icons.restaurant),
                                      ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Restaurant',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(data['address'] ?? 'No address provided'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text('Owner: ${data['ownerName'] ?? 'Not specified'}'),
                            Text('Phone: ${data['phone'] ?? 'Not provided'}'),
                            Text('Email: ${data['email'] ?? 'Not provided'}'),
                            SizedBox(height: 8),
                            Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(data['description'] ?? 'No description provided'),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: Text('Approve'),
                                  onPressed: () => _approveRestaurant(restaurant.id),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: Text('Reject'),
                                  onPressed: () => _showRejectRestaurantDialog(restaurant.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  int _calculateTotalMenuItems() {
    // This is a placeholder - in a real app you'd want to query this
    return _restaurantMenu.length;
  }

  String _formatTimestamp(Timestamp timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('MMM d, y • h:mm a').format(timestamp.toDate());
  }

  Future<void> _showDeleteMenuItemDialog(String restaurantId, String itemId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMenuItem(restaurantId, itemId);
    }
  }

  Future<void> _showRejectRestaurantDialog(String restaurantId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Rejection'),
        content: Text('Are you sure you want to reject this restaurant application? This cannot be undone.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Reject', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _rejectRestaurant(restaurantId);
    }
  }
}