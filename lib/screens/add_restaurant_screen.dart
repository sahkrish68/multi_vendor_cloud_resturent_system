import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRestaurantScreen extends StatefulWidget {
  @override
  _AddRestaurantScreenState createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  String _name = '';
  String _address = '';
  String _description = '';
  String _deliveryTime = '30-45';
  double _rating = 4.0;
  File? _image;
  bool _isFeatured = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      // In a real app, you would upload the image to Firebase Storage first
      // and get the download URL. Here we'll just use a placeholder.
      final imageUrl = 'https://via.placeholder.com/150';

      await _firestore.collection('restaurants').add({
        'name': _name,
        'address': _address,
        'description': _description,
        'deliveryTime': _deliveryTime,
        'rating': _rating,
        'imageUrl': imageUrl,
        'isFeatured': _isFeatured,
        'ownerId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding restaurant: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Restaurant'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null 
                      ? Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Restaurant Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _address = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              DropdownButtonFormField<String>(
                value: _deliveryTime,
                items: ['20-30', '30-45', '45-60']
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text('$time min delivery'),
                        ))
                    .toList(),
                onChanged: (value) => _deliveryTime = value!,
                decoration: InputDecoration(labelText: 'Delivery Time'),
              ),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) => setState(() => _rating = value),
              ),
              Text('Rating: ${_rating.toStringAsFixed(1)}'),
              SwitchListTile(
                title: Text('Featured Restaurant'),
                value: _isFeatured,
                onChanged: (value) => setState(() => _isFeatured = value),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Restaurant'),
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