import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
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
  final ImagePicker _picker = ImagePicker();
  int _currentIndex = 0;
  
  // Menu Item Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _category;
  String? _imageUrl;
  String? _editingItemId;
  File? _imageFile;

  // Restaurant Info
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _restaurantAddressController = TextEditingController();
  final TextEditingController _restaurantPhoneController = TextEditingController();
  final TextEditingController _restaurantDescriptionController = TextEditingController();
  String? _restaurantImageUrl;
  File? _restaurantImageFile;

  // Inventory
  final TextEditingController _inventoryNameController = TextEditingController();
  final TextEditingController _inventoryQuantityController = TextEditingController();
  final TextEditingController _inventoryUnitController = TextEditingController();
  final TextEditingController _inventoryThresholdController = TextEditingController();
  String? _editingInventoryId;

  // Staff
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _staffEmailController = TextEditingController();
  final TextEditingController _staffPhoneController = TextEditingController();
  final TextEditingController _staffRoleController = TextEditingController();
  String? _staffImageUrl;
  File? _staffImageFile;
  String? _editingStaffId;

  // Data
  List<SalesData> _weeklySales = [];
  List<PopularItem> _popularItems = [];
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _staffMembers = [];
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
    _loadStatistics();
    _loadInventory();
    _loadStaff();
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
          _restaurantImageUrl = restaurantSnapshot['imageUrl'];
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
        {'id': '1', 'name': 'John Doe', 'role': 'Manager', 'email': 'john@example.com'},
        {'id': '2', 'name': 'Jane Smith', 'role': 'Chef', 'email': 'jane@example.com'},
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_restaurantImageUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(_restaurantImageUrl!),
                        ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _restaurantNameController.text.isNotEmpty 
                                  ? _restaurantNameController.text 
                                  : 'Your Restaurant',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              _buildStatCard('Today\'s Orders', '12', Icons.shopping_bag, Colors.blue),
              _buildStatCard('Pending Orders', '5', Icons.access_time, Colors.orange),
              _buildStatCard('Total Revenue', '\$450', Icons.attach_money, Colors.green),
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

  Widget _buildMenuTab() {
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
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.fastfood)),
                  title: Text('Menu Item ${index + 1}'),
                  subtitle: Text('\$${(index + 5).toStringAsFixed(2)}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(child: Text('Edit'), value: 'edit'),
                      PopupMenuItem(child: Text('Delete'), value: 'delete'),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        // Implement edit
                      } else if (value == 'delete') {
                        // Implement delete
                      }
                    },
                  ),
                ),
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
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text('Order #${1000 + index}'),
            subtitle: Text('\$${(index + 1) * 15}.00 • ${DateFormat('MMM d, h:mm a').format(DateTime.now().subtract(Duration(hours: index)))}'),
            trailing: Chip(
              label: Text(status.toUpperCase(), style: TextStyle(color: Colors.white)),
              backgroundColor: _getStatusColor(status),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.fastfood),
                      title: Text('Item ${index + 1}'),
                      subtitle: Text('\$${(index + 1) * 5}.00'),
                      trailing: Text('x${index + 1}'),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Customer: John Doe'),
                      subtitle: Text('Phone: +1234567890'),
                    ),
                    if (status == 'pending' || status == 'preparing' || status == 'ready')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (status == 'pending')
                              ElevatedButton(
                                child: Text('Accept'),
                                onPressed: () {},
                              ),
                            if (status == 'preparing')
                              ElevatedButton(
                                child: Text('Mark Ready'),
                                onPressed: () {},
                              ),
                            if (status == 'ready')
                              ElevatedButton(
                                child: Text('Mark Delivered'),
                                onPressed: () {},
                              ),
                            if (status != 'ready')
                              OutlinedButton(
                                child: Text('Cancel'),
                                onPressed: () {},
                              ),
                          ],
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
                  leading: CircleAvatar(child: Icon(Icons.person)),
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

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
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
                hint: Text('Select Category'),
                items: ['Appetizer', 'Main Course', 'Dessert', 'Drink']
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
              _imageFile != null
                  ? Image.file(_imageFile!, height: 100)
                  : _imageUrl != null
                      ? Image.network(_imageUrl!, height: 100)
                      : Container(),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
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
              _staffImageFile != null
                  ? Image.file(_staffImageFile!, height: 100)
                  : _staffImageUrl != null
                      ? Image.network(_staffImageUrl!, height: 100)
                      : Container(),
              ElevatedButton(
                onPressed: _pickStaffImage,
                child: Text('Select Image'),
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

  Future<void> _pickStaffImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _staffImageFile = File(pickedFile.path);
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _restaurantPhoneController.dispose();
    _restaurantDescriptionController.dispose();
    _inventoryNameController.dispose();
    _inventoryQuantityController.dispose();
    _inventoryUnitController.dispose();
    _inventoryThresholdController.dispose();
    _staffNameController.dispose();
    _staffEmailController.dispose();
    _staffPhoneController.dispose();
    _staffRoleController.dispose();
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