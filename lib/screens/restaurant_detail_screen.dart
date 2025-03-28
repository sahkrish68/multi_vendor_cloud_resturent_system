import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImage;

  const RestaurantDetailScreen({
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
  });

  @override
  _RestaurantDetailScreenState createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Restaurant Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: widget.restaurantImage != null
                    ? DecorationImage(
                        image: NetworkImage(widget.restaurantImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[200],
              ),
              child: widget.restaurantImage == null
                  ? Center(child: Icon(Icons.restaurant, size: 100, color: Colors.grey))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Add more restaurant details here as needed
                ],
              ),
            ),
            Divider(),
            // Menu Items
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('restaurants')
                  .doc(widget.restaurantId)
                  .collection('menu')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No menu items available'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var menuItem = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: menuItem['imageUrl'] != null
                            ? Image.network(
                                menuItem['imageUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(Icons.fastfood),
                              ),
                        title: Text(menuItem['name']),
                        subtitle: Text(
                          '\$${menuItem['price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            // Add to cart functionality
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
      ),
    );
  }
}