import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'restaurant_detail_screen.dart';
import 'cart_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0 
            ? Text('Food Delivery')
            : Text('Search Restaurants'),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _getBody(_currentIndex),
      bottomNavigationBar: _buildBottomNavBar(),
    );
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

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for restaurants or dishes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          _buildSectionHeader('All Restaurants'),
          _buildRestaurantList(
           query: _firestore.collection('restaurants').limit(20),
          ),

          
          _buildSectionHeader('Categories'),
          _buildCategoryGrid(),

          _buildSectionHeader('Near You'),
          _buildRestaurantList(
            query: _firestore.collection('restaurants')
              .orderBy('distance', descending: false)
              .limit(10)
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search restaurants, dishes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: _buildRestaurantList(
            query: _searchQuery.isNotEmpty
              ? _firestore.collection('restaurants')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThan: _searchQuery + 'z')
              : _firestore.collection('restaurants').limit(10)
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Please sign in to view favorites'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: CircularProgressIndicator());
        }
        
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
          query: _firestore.collection('restaurants')
            .where(FieldPath.documentId, whereIn: favorites)
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Guest User'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading profile'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: data['photoUrl'] != null 
                    ? NetworkImage(data['photoUrl'])
                    : null,
                child: data['photoUrl'] == null 
                    ? Icon(Icons.person, size: 50)
                    : null,
              ),
              SizedBox(height: 16),
              Text(
                data['name'] ?? 'No Name',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(data['email'] ?? ''),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.history),
                title: Text('Order History'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.favorite),
                title: Text('Favorites'),
                onTap: () => setState(() => _currentIndex = 2),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {},
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    List<Map<String, dynamic>> categories = [
      {'name': 'Pizza', 'icon': Icons.local_pizza},
      {'name': 'Burger', 'icon': Icons.fastfood},
      {'name': 'Sushi', 'icon': Icons.set_meal},
      {'name': 'Pasta', 'icon': Icons.restaurant},
      {'name': 'Salad', 'icon': Icons.eco},
      {'name': 'Dessert', 'icon': Icons.cake},
      {'name': 'Drinks', 'icon': Icons.local_drink},
      {'name': 'View All', 'icon': Icons.more_horiz},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categories[index]['icon'], size: 30),
                SizedBox(height: 8),
                Text(categories[index]['name']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantList({required Query query}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading restaurants'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No restaurants found'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var restaurant = snapshot.data!.docs[index];
            final data = restaurant.data() as Map<String, dynamic>? ?? {};
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['imageUrl'] != null
                      ? NetworkImage(data['imageUrl'])
                      : null,
                  child: data['imageUrl'] == null
                      ? Icon(Icons.restaurant)
                      : null,
                ),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['address'] ?? ''),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        Text(' ${data['rating']?.toStringAsFixed(1) ?? '0.0'}'),
                        Text(' • ${data['deliveryTime'] ?? '20-30'} min'),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(
                        restaurantId: restaurant.id,
                        restaurantName: data['name'] ?? 'Unknown',
                        restaurantImage: data['imageUrl'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}