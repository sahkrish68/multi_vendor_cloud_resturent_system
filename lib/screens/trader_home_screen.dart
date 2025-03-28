import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _restaurantFormKey = GlobalKey<FormState>();
  
  // Menu Item Controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  String? _category;
  String? _imageUrl;
  String? _editingItemId;
  File? _imageFile;

  // Restaurant Info Controllers
  TextEditingController _restaurantNameController = TextEditingController();
  TextEditingController _restaurantAddressController = TextEditingController();
  TextEditingController _restaurantPhoneController = TextEditingController();
  TextEditingController _restaurantDescriptionController = TextEditingController();
  String? _restaurantImageUrl;
  File? _restaurantImageFile;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Restaurant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0: return _buildDashboardTab();
      case 1: return _buildMenuTab();
      case 2: return _buildOrdersTab();
      case 3: return _buildRestaurantTab();
      case 4: return _buildAnalyticsTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Info Card
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
                              style: TextStyle(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (_restaurantAddressController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      _restaurantAddressController.text,
                                      style: TextStyle(color: Colors.grey),
                                    ),
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
                                    Text(
                                      _restaurantPhoneController.text,
                                      style: TextStyle(color: Colors.grey),
                                    ),
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
                      child: Text(
                        _restaurantDescriptionController.text,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Business Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
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
          Text(
            'Recent Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('orders')
                .where('restaurantId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              
              var orders = snapshot.data!.docs;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var order = orders[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('Order #${order.id.substring(0, 8)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$${order['totalAmount'].toStringAsFixed(2)}'),
                          Text('${order['items'].length} items • ${_formatTime(order['createdAt'].toDate())}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          order['status'],
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(order['status']),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
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
              Text(
                'Menu Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Item'),
                onPressed: () => _showAddMenuItemDialog(),
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('restaurants')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('menu')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.data!.docs.isEmpty) {
                return Column(
                  children: [
                    SizedBox(height: 40),
                    Icon(Icons.menu_book, size: 60, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      'No menu items yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first menu item to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }
              
              var menuItems = snapshot.data!.docs;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  var item = menuItems[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8),
                      leading: item['imageUrl'] != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.fastfood, size: 30, color: Colors.grey),
                            ),
                      title: Text(
                        item['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${item['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item['description'] != null && item['description'].isNotEmpty)
                            Text(
                              item['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text('Edit'),
                            value: 'edit',
                          ),
                          PopupMenuItem(
                            child: Text('Delete'),
                            value: 'delete',
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditMenuItemDialog(item);
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
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status orders',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        
        var orders = snapshot.data!.docs;
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text('Order #${order.id.substring(0, 8)}'),
                subtitle: Text(
                  '\$${order['totalAmount'].toStringAsFixed(2)} • ${_formatTime(order['createdAt'].toDate())}',
                ),
                trailing: Chip(
                  label: Text(
                    order['status'].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(order['status']),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        ...order['items'].map<Widget>((item) => ListTile(
                          leading: item['imageUrl'] != null
                              ? Image.network(
                                  item['imageUrl'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.fastfood),
                          title: Text(item['name']),
                          subtitle: Text('\$${item['price'].toStringAsFixed(2)}'),
                          trailing: Text('x${item['quantity']}'),
                        )).toList(),
                        Divider(),
                        ListTile(
                          title: Text('Customer: ${order['customerName'] ?? 'N/A'}'),
                          subtitle: Text('Phone: ${order['customerPhone'] ?? 'N/A'}'),
                        ),
                        if (order['deliveryAddress'] != null)
                          ListTile(
                            leading: Icon(Icons.location_on),
                            title: Text('Delivery Address'),
                            subtitle: Text(order['deliveryAddress']),
                          ),
                        SizedBox(height: 8),
                        if (status == 'pending' || status == 'preparing' || status == 'ready')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (status == 'pending')
                                  ElevatedButton(
                                    child: Text('Accept'),
                                    onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                                  ),
                                if (status == 'preparing')
                                  ElevatedButton(
                                    child: Text('Mark Ready'),
                                    onPressed: () => _updateOrderStatus(order.id, 'ready'),
                                  ),
                                if (status == 'ready')
                                  ElevatedButton(
                                    child: Text('Mark Delivered'),
                                    onPressed: () => _updateOrderStatus(order.id, 'completed'),
                                  ),
                                if (status != 'ready')
                                  OutlinedButton(
                                    child: Text('Cancel'),
                                    onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
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
      },
    );
  }

  Widget _buildRestaurantTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Restaurant Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Form(
            key: _restaurantFormKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickRestaurantImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _restaurantImageFile != null
                        ? FileImage(_restaurantImageFile!)
                        : (_restaurantImageUrl != null
                            ? NetworkImage(_restaurantImageUrl!)
                            : null),
                    child: _restaurantImageFile == null && _restaurantImageUrl == null
                        ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _restaurantNameController,
                  decoration: InputDecoration(
                    labelText: 'Restaurant Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _restaurantAddressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _restaurantPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _restaurantDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Save Information'),
                  onPressed: _saveRestaurantInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sales Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Sales Chart - Last 7 Days',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Popular Items - This Month',
                style: TextStyle(fontSize: 18),
              ),
            ),
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

  Future<void> _pickRestaurantImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _restaurantImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Upload file to Firebase Storage
      String fileName = 'menu_items/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(_imageFile!);
      
      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _imageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  Future<void> _uploadRestaurantImage() async {
    if (_restaurantImageFile == null) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Upload file to Firebase Storage
      String fileName = 'restaurants/${user.uid}/logo.jpg';
      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(_restaurantImageFile!);
      
      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _restaurantImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  void _showAddMenuItemDialog() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _category = null;
    _imageUrl = null;
    _imageFile = null;
    _editingItemId = null;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Menu Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 40),
                                          Text('Add Image'),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Appetizer', 'Main Course', 'Dessert', 'Drink', 'Side']
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _category = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  ),
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
                    if (_formKey.currentState!.validate()) {
                      if (_imageFile != null) {
                        await _uploadImage();
                      }
                      _saveMenuItem();
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMenuItemDialog(DocumentSnapshot item) {
    _nameController.text = item['name'];
    _priceController.text = item['price'].toString();
    _descriptionController.text = item['description'] ?? '';
    _category = item['category'];
    _imageUrl = item['imageUrl'];
    _editingItemId = item.id;
    _imageFile = null;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Menu Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 40),
                                          Text('Add Image'),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Appetizer', 'Main Course', 'Dessert', 'Drink', 'Side']
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _category = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text('Update'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_imageFile != null) {
                        await _uploadImage();
                      }
                      _saveMenuItem();
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMenuItem() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> menuItem = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'description': _descriptionController.text,
      'category': _category,
      'imageUrl': _imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_editingItemId == null) {
      // Add new item
      menuItem['createdAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('restaurants')
          .doc(user.uid)
          .collection('menu')
          .add(menuItem);
    } else {
      // Update existing item
      await _firestore
          .collection('restaurants')
          .doc(user.uid)
          .collection('menu')
          .doc(_editingItemId)
          .update(menuItem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingItemId == null ? 'Menu item added!' : 'Menu item updated!')),
    );
  }

  Future<void> _deleteMenuItem(String itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
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
      await _firestore
          .collection('restaurants')
          .doc(user.uid)
          .collection('menu')
          .doc(itemId)
          .delete();
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item deleted')),
      );
    }
  }

  Future<void> _saveRestaurantInfo() async {
    if (_restaurantFormKey.currentState!.validate()) {
      if (_restaurantImageFile != null) {
        await _uploadRestaurantImage();
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('restaurants').doc(user.uid).set({
        'name': _restaurantNameController.text,
        'address': _restaurantAddressController.text,
        'phone': _restaurantPhoneController.text,
        'description': _restaurantDescriptionController.text,
        'imageUrl': _restaurantImageUrl,
        'ownerId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant information saved successfully')),
      );
      
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.purple;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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
    super.dispose();
  }
}