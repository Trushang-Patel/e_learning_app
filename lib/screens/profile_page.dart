import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Import for image processing

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _educationLevelController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists) {
          setState(() {
            _usernameController.text = userData['username'] ?? '';
            _dobController.text = userData['dob'] ?? '';
            _educationLevelController.text = userData['educationLevel'] ?? '';
            _profileImageUrl = userData.data()?.containsKey('profileImageUrl') == true
                ? userData['profileImageUrl']
                : ''; // Handle missing field
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print('Picked file path: ${pickedFile.path}'); // Debugging: Log the file path
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    } else {
      print('No image selected.');
    }
  }

  Future<void> _uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _profileImage != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');

      // Read the image bytes
      final imageBytes = await _profileImage!.readAsBytes();

      // Decode the image
      final decodedImage = img.decodeImage(imageBytes);

      // Resize the image to a maximum width/height of 300 pixels
      final resizedImage = img.copyResize(decodedImage!, width: 300, height: 300);

      // Compress the image by reducing the quality (e.g., 70%)
      final jpgImage = img.encodeJpg(resizedImage, quality: 70);

      // Upload the resized and compressed image to Firebase Storage
      await storageRef.putData(
        Uint8List.fromList(jpgImage),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get the download URL of the uploaded image
      final downloadUrl = await storageRef.getDownloadURL();
      setState(() {
        _profileImageUrl = downloadUrl;
      });

      // Save the download URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageUrl': _profileImageUrl,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text,
          'dob': _dobController.text,
          'educationLevel': _educationLevelController.text,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 150, // Adjust size as needed
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('assets/images/profile_placeholder.png')) as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your date of birth';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _educationLevelController,
                decoration: InputDecoration(labelText: 'Education Level'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your education level';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveUserData,
                child: Text('Save'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut(); // Sign out the user
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Navigate to login page
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}