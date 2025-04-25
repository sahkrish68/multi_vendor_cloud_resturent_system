import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class TraderHomeScreen extends StatefulWidget {
  @override
  _TraderHomeScreenState createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  int _currentIndex = 0;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _restaurantAddressController = TextEditingController();
  final TextEditingController _restaurantPhoneController = TextEditingController();
  final TextEditingController _restaurantDescriptionController = TextEditingController();
  final TextEditingController _restaurantImageUrlController = TextEditingController();
  final TextEditingController _inventoryNameController = TextEditingController();
  final TextEditingController _inventoryQuantityController = TextEditingController();
  final TextEditingController _inventoryUnitController = TextEditingController();
  final TextEditingController _inventoryThresholdController = TextEditingController();
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _staffEmailController = TextEditingController();
  final TextEditingController _staffPhoneController = TextEditingController();
  final TextEditingController _staffRoleController = TextEditingController();
  final TextEditingController _staffImageUrlController = TextEditingController();

  // State variables
  String? _category;
  String? _editingItemId;
  String? _editingInventoryId;
  String? _editingStaffId;
  List<SalesData> _weeklySales = [];
  List<PopularItem> _popularItems = [];
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _staffMembers = [];
  bool _isLoadingStats = true;
  List<DocumentSnapshot> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
    _loadStatistics();
    _loadInventory();
    _loadStaff();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print("👤 Logged-in Trader UID: ${user.uid}");

      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _orders = orderSnapshot.docs;
      });
    } catch (e) {
      print("Error loading orders: $e");
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadOrders(); // Refresh orders after update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  Future<void> _loadRestaurantInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot restaurantSnapshot = await _firestore
          .collection('restaurants')
          .doc(user.uid)
          .get();
      
      if (restaurantSnapshot.exists) {
        setState(() {
          _restaurantNameController.text = restaurantSnapshot['name'] ?? '';
          _restaurantAddressController.text = restaurantSnapshot['address'] ?? '';
          _restaurantPhoneController.text = restaurantSnapshot['phone'] ?? '';
          _restaurantDescriptionController.text = restaurantSnapshot['description'] ?? '';
          _restaurantImageUrlController.text = restaurantSnapshot['imageUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    
    // Mock data
    _weeklySales = [
      SalesData('Mon', 450),
      SalesData('Tue', 600),
      SalesData('Wed', 300),
      SalesData('Thu', 750),
      SalesData('Fri', 500),
      SalesData('Sat', 650),
      SalesData('Sun', 800),
    ];

    _popularItems = [
      PopularItem("Margherita Pizza", 42),
      PopularItem("Chicken Burger", 35),
      PopularItem("Caesar Salad", 28),
      PopularItem("Pasta Carbonara", 25),
      PopularItem("Chocolate Cake", 20),
    ];

    setState(() => _isLoadingStats = false);
  }

  Future<void> _loadInventory() async {
    setState(() {
      _inventory = [
        {'id': '1', 'name': 'Flour', 'quantity': 20, 'unit': 'kg', 'threshold': 5},
        {'id': '2', 'name': 'Tomato Sauce', 'quantity': 15, 'unit': 'L', 'threshold': 3},
        {'id': '3', 'name': 'Cheese', 'quantity': 8, 'unit': 'kg', 'threshold': 2},
      ];
    });
  }

  Future<void> _loadStaff() async {
    setState(() {
      _staffMembers = [
        {'id': '1', 'name': 'John Doe', 'role': 'Manager', 'email': 'john@example.com', 'imageUrl': ''},
        {'id': '2', 'name': 'Jane Smith', 'role': 'Chef', 'email': 'jane@example.com', 'imageUrl': ''},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurantNameController.text.isNotEmpty 
            ? _restaurantNameController.text 
            : 'Restaurant Dashboard'),
        actions: [
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
      body: _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0: return _buildDashboardTab();
      case 1: return _buildMenuTab();
      case 2: return _buildOrdersTab();
      case 3: return _buildInventoryTab();
      case 4: return _buildStaffTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_restaurantImageUrlController.text.isNotEmpty)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(_restaurantImageUrlController.text),
                        ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _restaurantNameController.text.isNotEmpty
                                        ? _restaurantNameController.text
                                        : 'Your Restaurant',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: _showEditRestaurantDialog,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (_restaurantAddressController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(_restaurantAddressController.text),
                                  ],
                                ),
                              ),
                            if (_restaurantPhoneController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(_restaurantPhoneController.text),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_restaurantDescriptionController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_restaurantDescriptionController.text),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text('Business Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Today\'s Orders', '${_orders.length}', Icons.shopping_bag, Colors.blue),
              _buildStatCard('Pending Orders', '${_orders.where((o) => o['status'] == 'pending').length}', Icons.access_time, Colors.orange),
              _buildStatCard('Total Revenue', '\$${_orders.fold(0.0, (sum, o) => sum + (o['total'] ?? 0.0)).toStringAsFixed(2)}', Icons.attach_money, Colors.green),
              _buildStatCard('Menu Items', '24', Icons.restaurant, Colors.purple),
            ],
          ),
          SizedBox(height: 24),
          Text('Sales Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Container(
              height: 250,
              padding: EdgeInsets.all(16),
              child: _isLoadingStats
                  ? Center(child: CircularProgressIndicator())
                  : _buildCustomBarChart(),
            ),
          ),
          SizedBox(height: 24),
          Text('Popular Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _popularItems.length,
            itemBuilder: (context, index) {
              var item = _popularItems[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(item.name),
                subtitle: Text('${item.orderCount} orders'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please sign in to manage menu'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menu Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Item'),
                onPressed: _showAddMenuItemDialog,
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('restaurants')
                .doc(user.uid)
                .collection('menu')
                .orderBy('createdAt')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.data?.docs.isEmpty ?? true) {
                return Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text('No menu items yet. Add your first item!'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  var item = snapshot.data!.docs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: item['imageUrl']?.isNotEmpty ?? false
                          ? CircleAvatar(backgroundImage: NetworkImage(item['imageUrl']))
                          : CircleAvatar(child: Icon(Icons.fastfood)),
                      title: Text(item['name']),
                      subtitle: Text('\$${item['price'].toStringAsFixed(2)} • ${item['category']}'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(child: Text('Edit'), value: 'edit'),
                          PopupMenuItem(child: Text('Delete'), value: 'delete'),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editMenuItem(item);
                          } else if (value == 'delete') {
                            _deleteMenuItem(item.id);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

 Widget _buildOrdersTab() {
  return DefaultTabController(
    length: 4,
    child: Column(
      children: [
        Material(
          child: TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Preparing'),
              Tab(text: 'Ready'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildOrderList('pending'),
              _buildOrderList('preparing'),
              _buildOrderList('ready'),
              _buildOrderList('completed'),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildOrderList(String status) {
  final filteredOrders = _orders.where((order) => order['status'] == status).toList();

  if (filteredOrders.isEmpty) {
    return Center(child: Text('No $status orders'));
  }

  return ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: filteredOrders.length,
    itemBuilder: (context, index) {
      final order = filteredOrders[index];
      final orderData = order.data() as Map<String, dynamic>;
      final items = orderData['items'] as List<dynamic>? ?? [];
      final createdAt = orderData['createdAt']?.toDate() ?? DateTime.now();

      return Card(
        margin: EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          title: Text('Order #${order.id.substring(0, 8)}'),
          subtitle: Text(
            '\$${orderData['total']?.toStringAsFixed(2) ?? '0.00'} • '
            '${DateFormat('MMM d, h:mm a').format(createdAt)}'
          ),
          trailing: Chip(
            label: Text(status.toUpperCase(), style: TextStyle(color: Colors.white)),
            backgroundColor: _getStatusColor(status),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ...items.map((item) => ListTile(
                    leading: Icon(Icons.fastfood),
                    title: Text(item['name'] ?? 'Unknown Item'),
                    subtitle: Text('\$${item['price']?.toStringAsFixed(2) ?? '0.00'}'),
                    trailing: Text('x${item['quantity'] ?? '1'}'),
                  )),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _buildOrderActionButtons(status, order.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  List<Widget> _buildOrderActionButtons(String status, String orderId) {
  switch (status) {
    case 'pending':
      return [
        ElevatedButton(
          child: Text('Accept Order'),
          onPressed: () => _updateOrderStatus(orderId, 'preparing'),
        ),
        OutlinedButton(
          child: Text('Reject'),
          onPressed: () => _updateOrderStatus(orderId, 'rejected'),
        ),
      ];
    case 'preparing':
      return [
        ElevatedButton(
          child: Text('Mark Ready'),
          onPressed: () => _updateOrderStatus(orderId, 'ready'),
        ),
        OutlinedButton(
          child: Text('Cancel'),
          onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
        ),
      ];
    case 'ready':
      return [
        ElevatedButton(
          child: Text('Mark Delivered'),
          onPressed: () => _updateOrderStatus(orderId, 'completed'),
        ),
      ];
    default:
      return [];
  }
}

  Widget _buildInventoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                child: Text('Add Item'),
                onPressed: _showAddInventoryDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _inventory.length,
            itemBuilder: (context, index) {
              var item = _inventory[index];
              bool isLowStock = (item['quantity'] ?? 0) <= (item['threshold'] ?? 0);
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item['name']),
                  subtitle: Text('Stock: ${item['quantity']} ${item['unit'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLowStock) Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () {}),
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

  Widget _buildStaffTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Staff Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                child: Text('Add Staff'),
                onPressed: _showAddStaffDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _staffMembers.length,
            itemBuilder: (context, index) {
              var staff = _staffMembers[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: staff['imageUrl']?.isNotEmpty ?? false
                        ? Image.network(staff['imageUrl'])
                        : Icon(Icons.person),
                  ),
                  title: Text(staff['name']),
                  subtitle: Text(staff['role']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () {}),
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

  Widget _buildCustomBarChart() {
    double maxValue = _weeklySales.map((e) => e.amount).reduce((a, b) => a > b ? a : b).toDouble();
    
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _weeklySales.map((data) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text('\$${data.amount}', style: TextStyle(fontSize: 10)),
                      SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          height: (data.amount / maxValue) * 100,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weeklySales.map((data) {
            return Text(data.day, style: TextStyle(fontSize: 12));
          }).toList(),
        ),
      ],
    );
  }

  void _showEditRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Restaurant Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _restaurantNameController,
                decoration: InputDecoration(labelText: 'Restaurant Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _restaurantAddressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _restaurantPhoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _restaurantDescriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _restaurantImageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await _firestore.collection('restaurants').doc(user.uid).set({
                  'name': _restaurantNameController.text.trim(),
                  'address': _restaurantAddressController.text.trim(),
                  'phone': _restaurantPhoneController.text.trim(),
                  'description': _restaurantDescriptionController.text.trim(),
                  'imageUrl': _restaurantImageUrlController.text.trim(),
                }, SetOptions(merge: true));
              }
              Navigator.pop(context);
              setState(() {}); // Refresh dashboard with updated info
            },
          ),
        ],
      ),
    );
  }

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingItemId == null ? 'Add Menu Item' : 'Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name*'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price*'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                hint: Text('Select Category*'),
                items: ['Appetizer', 'Main Course', 'Dessert', 'Drink','Sushi','Pizza','Burger','Momo']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              _clearMenuItemFields();
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () async {
              if (_nameController.text.isEmpty ||
                  _priceController.text.isEmpty ||
                  _category == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all required fields (*)')),
                );
                return;
              }

              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                double price = double.tryParse(_priceController.text) ?? 0.0;

if (_editingItemId == null) {
  // Add new item
  await _firestore
      .collection('restaurants')
      .doc(user.uid)
      .collection('menu')
      .add({
    'name': _nameController.text.trim(),
    'price': price,
    'description': _descriptionController.text.trim(),
    'category': _category,
    'imageUrl': _imageUrlController.text.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });
} else {
  // Update existing item
  await _firestore
      .collection('restaurants')
      .doc(user.uid)
      .collection('menu')
      .doc(_editingItemId)
      .update({
    'name': _nameController.text.trim(),
    'price': price,
    'description': _descriptionController.text.trim(),
    'category': _category,
    'imageUrl': _imageUrlController.text.trim(),
  });
}
if (_category != null) {
  await _firestore
      .collection('restaurants')
      .doc(user.uid)
      .set({
    'categories': FieldValue.arrayUnion([_category!.toLowerCase()])
  }, SetOptions(merge: true));
}

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Menu item saved successfully!')),
                );
                _clearMenuItemFields();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving item: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _editMenuItem(DocumentSnapshot item) {
    _nameController.text = item['name'];
    _priceController.text = item['price'].toString();
    _descriptionController.text = item['description'] ?? '';
    _imageUrlController.text = item['imageUrl'] ?? '';
    _category = item['category'];
    _editingItemId = item.id;

    _showAddMenuItemDialog();
  }

  Future<void> _deleteMenuItem(String itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
      try {
        await _firestore
            .collection('restaurants')
            .doc(user.uid)
            .collection('menu')
            .doc(itemId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _showAddInventoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _inventoryNameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _inventoryQuantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _inventoryUnitController,
                decoration: InputDecoration(labelText: 'Unit (kg, L, etc.)'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _inventoryThresholdController,
                decoration: InputDecoration(labelText: 'Low Stock Threshold'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              // Save logic here
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Staff Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _staffNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _staffEmailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _staffPhoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _staffRoleController,
                decoration: InputDecoration(labelText: 'Role'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _staffImageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              // Save logic here
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _clearMenuItemFields() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _category = null;
    _editingItemId = null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.purple;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _restaurantPhoneController.dispose();
    _restaurantDescriptionController.dispose();
    _restaurantImageUrlController.dispose();
    _inventoryNameController.dispose();
    _inventoryQuantityController.dispose();
    _inventoryUnitController.dispose();
    _inventoryThresholdController.dispose();
    _staffNameController.dispose();
    _staffEmailController.dispose();
    _staffPhoneController.dispose();
    _staffRoleController.dispose();
    _staffImageUrlController.dispose();
    super.dispose();
  }
}

class SalesData {
  final String day;
  final int amount;

  SalesData(this.day, this.amount);
}

class PopularItem {
  final String name;
  final int orderCount;

  PopularItem(this.name, this.orderCount);
}