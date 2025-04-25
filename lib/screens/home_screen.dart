import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'restaurant_detail_screen.dart';
import 'cart_screen.dart';
import 'category_restaurants_screen.dart';
import 'order_history_screen.dart'; // Import the missing screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'favorites': [],
          'cart': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF2E6),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFF2E6),
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Image.asset('assets/images/khauu_logo.png', height: 40),
            SizedBox(width: 10),
            Text(
              'Khauu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C2A),
              ),
            ),
            Spacer(),
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(_firebaseAuth.currentUser?.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();
                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? '';
                return Text(
                  'Hi, $name',
                  style: TextStyle(color: Color(0xFF4A2C2A), fontSize: 16),
                );
              },
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Color(0xFF4A2C2A)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF4A2C2A)),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _getBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4A2C2A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0: return _buildHomeTab();
      case 1: return _buildSearchTab();
      case 2: return _buildFavoritesTab();
      case 3: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

 Widget _buildHomeTab() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),

        _buildRestaurantList(
          title: 'All Restaurants',
          query: _firestore.collection('restaurants').limit(20),
        ),

        _buildSectionHeader('Categories'),
        _buildCategoryGrid(),

        _buildRestaurantList(
          title: 'Near You',
          query: _firestore
              .collection('restaurants')
              .orderBy('distance')
              .limit(10),
        ),
      ],
    ),
  );
}

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildRestaurantList(
            title: 'Search Results',
            query: _searchQuery.isNotEmpty
              ? _firestore.collection('restaurants')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThan: _searchQuery + 'z')
              : _firestore.collection('restaurants').limit(10),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return _buildAuthPrompt('Please sign in to view favorites');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final favorites = List<String>.from(data['favorites'] ?? []);

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No favorites yet'),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 0),
                  child: Text('Browse restaurants'),
                ),
              ],
            ),
          );
        }
        return _buildRestaurantList(
          title: 'Your Favorites',
          query: _firestore.collection('restaurants')
              .where(FieldPath.documentId, whereIn: favorites),
        );
      },
    );
  }

  Widget _buildProfileTab() {
  final userId = _firebaseAuth.currentUser?.uid;
  if (userId == null) return _buildAuthPrompt('Guest User');

  return StreamBuilder<DocumentSnapshot>(
    stream: _firestore.collection('users').doc(userId).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Error loading profile'));
      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
              child: data['photoUrl'] == null ? Icon(Icons.person, size: 50) : null,
            ),
            SizedBox(height: 16),
            Text(
              data['name'] ?? 'No Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(data['email'] ?? ''),
            SizedBox(height: 24),

            // ✅ Order History Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Order History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error loading orders');
                if (!snapshot.hasData) return CircularProgressIndicator();

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No orders yet.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
                    final status = order['status'] ?? 'unknown';
                    final total = order['total'] ?? 0.0;
                    final restaurant = order['restaurantName'] ?? 'Restaurant';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.receipt_long),
                        title: Text('$restaurant • ₹$total'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${status.toUpperCase()}'),
                            if (createdAt != null)
                              Text('Ordered: ${DateFormat.yMd().add_jm().format(createdAt)}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favorites'),
              onTap: () => setState(() => _currentIndex = 2),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {}, // Add settings navigation if needed
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signOut,
              child: Text('Sign Out'),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for restaurants or dishes...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    List<Map<String, dynamic>> categories = [
      {'name': 'Appetizer', 'icon': Icons.restaurant_menu},
      {'name': 'Main Course', 'icon': Icons.rice_bowl},
      {'name': 'Dessert', 'icon': Icons.cake},
      {'name': 'Drink', 'icon': Icons.local_drink},
      {'name': 'Sushi', 'icon': Icons.set_meal},
      {'name': 'Pizza', 'icon': Icons.local_pizza},
      {'name': 'Burger', 'icon': Icons.fastfood},
      {'name': 'Momo', 'icon': Icons.ramen_dining},
      {'name': 'View All', 'icon': Icons.more_horiz},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryRestaurantsScreen(
                    category: categories[index]['name'],
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categories[index]['icon'], size: 30, color: Color(0xFF4A2C2A)),
                SizedBox(height: 8),
                Text(categories[index]['name']),
              ],
            ),
          ),
        );
      },
    );
  }

 Widget _buildRestaurantList({
  required String title,
  required Query query,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(title),
      SizedBox(
        height: 250,
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error loading $title'));
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return Center(child: Text('No restaurants'));

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};

                return Container(
                  width: 170,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(
                            restaurantId: doc.id,
                            restaurantName: data['name'] ?? '',
                            restaurantImage: data['imageUrl'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                            child: data['imageUrl'] != null
                                ? Image.network(
                                    data['imageUrl'],
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.restaurant, size: 40),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(data['rating']?.toStringAsFixed(1) ?? '0.0'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  data['deliveryTime'] != null
                                      ? '${data['deliveryTime']} min'
                                      : '20-30 min',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
Widget _buildOrderHistory() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Center(child: Text('Please log in'));

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

      final orders = snapshot.data!.docs;

      if (orders.isEmpty) return Center(child: Text('No orders yet'));

      return ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index].data() as Map<String, dynamic>;
          final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
          final status = order['status'] ?? 'unknown';
          final total = order['total'] ?? 0.0;
          final restaurant = order['restaurantName'] ?? 'Restaurant';

          return ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('$restaurant • ₹$total'),
            subtitle: Text(
              'Status: $status\n${createdAt != null ? DateFormat.yMd().add_jm().format(createdAt) : 'Unknown date'}',
            ),
          );
        },
      );
    },
  );
}



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A2C2A)),
      ),
    );
  }

  Widget _buildAuthPrompt(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            ),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
