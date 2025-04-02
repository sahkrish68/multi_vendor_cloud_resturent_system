import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMenuItemScreen extends StatefulWidget {
  final String restaurantId;

  AddMenuItemScreen({required this.restaurantId});

  @override
  _AddMenuItemScreenState createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  
  String _name = '';
  String _description = '';
  double _price = 0.0;
  String _category = 'Main Course';
  String _imageUrl = '';
  bool _isLoading = false;

  final List<String> _categories = [
    'Appetizer',
    'Main Course',
    'Dessert',
    'Drink',
    'Side Dish'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an image URL')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menuItems')
          .add({
        'name': _name,
        'description': _description,
        'price': _price,
        'category': _category,
        'imageUrl': _imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Menu Item'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _imageUrl = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) => _category = value!,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Menu Item'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}