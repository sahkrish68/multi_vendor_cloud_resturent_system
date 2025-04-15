import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_detail_screen.dart';

class CategoryRestaurantsScreen extends StatelessWidget {
  final String category;

  const CategoryRestaurantsScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('restaurants')
        .where('categories', arrayContains: category.toLowerCase());

    return Scaffold(
      appBar: AppBar(title: Text('$category Restaurants')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error loading restaurants'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No restaurants found for "$category"'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['imageUrl'] != null
                        ? NetworkImage(data['imageUrl'])
                        : null,
                    child: data['imageUrl'] == null ? Icon(Icons.restaurant) : null,
                  ),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text(data['address'] ?? ''),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailScreen(
                          restaurantId: doc.id,
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
      ),
    );
  }
}
