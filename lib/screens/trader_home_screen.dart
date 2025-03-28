import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class TraderHomeScreen extends StatefulWidget {
  @override
  _TraderHomeScreenState createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Restaurant Dashboard'),
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
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildMenuTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Today\'s Orders', '12', Icons.shopping_bag),
              _buildStatCard('Pending Orders', '5', Icons.access_time),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Revenue', '\$450', Icons.attach_money),
              _buildStatCard('Menu Items', '24', Icons.restaurant),
            ],
          ),
          SizedBox(height: 30),
          Text(
            'Recent Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text('Order #100${index + 1}'),
                  subtitle: Text('\$25.99 • 30 mins ago'),
                  trailing: Chip(
                    label: Text(
                      ['Pending', 'Preparing', 'Ready', 'Delivered'][index % 4],
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: [
                      Colors.orange,
                      Colors.blue,
                      Colors.green,
                      Colors.purple
                    ][index % 4],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
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
              ElevatedButton(
                child: Text('Add New Item'),
                onPressed: () {
                  // Navigate to add new item screen
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: Image.network('https://via.placeholder.com/50'),
                  title: Text('Menu Item ${index + 1}'),
                  subtitle: Text('\$${(index + 5).toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {},
                      ),
                    ],
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Preparing'),
                    Tab(text: 'Ready'),
                    Tab(text: 'Delivered'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _buildOrderList('Pending'),
                      _buildOrderList('Preparing'),
                      _buildOrderList('Ready'),
                      _buildOrderList('Delivered'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Order #100${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: John Doe'),
                Text('Items: ${index + 2}'),
                Text('Total: \$${(index + 2) * 10}.00'),
              ],
            ),
            trailing: status == 'Pending'
                ? ElevatedButton(
                    child: Text('Accept'),
                    onPressed: () {},
                  )
                : status == 'Preparing'
                    ? ElevatedButton(
                        child: Text('Mark Ready'),
                        onPressed: () {},
                      )
                    : status == 'Ready'
                        ? ElevatedButton(
                            child: Text('Mark Delivered'),
                            onPressed: () {},
                          )
                        : Text('Completed'),
          ),
        );
      },
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
            width: 300,
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: Center(child: Text('Sales Chart')),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            width: 300,
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: Center(child: Text('Popular Items Chart')),
          ),
        ],
      ),
    );
  }
}