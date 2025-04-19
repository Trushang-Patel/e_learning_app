import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'dart:convert'; // Import for base64 encoding
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Import for image processing
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'package:e_learning_app/screens/login_page.dart';

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
  Map<String, dynamic>? userData;
  bool _isUploading = false; // Add this variable to your class state
  final int maxImageSizeBytes = 1048576; // 1MB limit for Firestore document size

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDataSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDataSnapshot.exists) {
          setState(() {
            userData = userDataSnapshot.data();
            _usernameController.text = userData?['username'] ?? '';
            _dobController.text = userData?['dob'] ?? '';
            _educationLevelController.text = userData?['educationLevel'] ?? '';
            // Fix the profileImageUrl loading
            _profileImageUrl = userData?['profileImageUrl'] ?? '';
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
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,  // Pre-scale during picking to reduce memory usage
      maxHeight: 800,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int fileSize = await imageFile.length();
      
      if (fileSize > maxImageSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image too large. Please choose a smaller image.')),
        );
        return;
      }
      
      setState(() {
        _profileImage = imageFile;
      });
      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _profileImage != null) {
      try {
        // Read and resize image
        final imageBytes = await _profileImage!.readAsBytes();
        final decodedImage = img.decodeImage(imageBytes);
        
        // Start with higher compression if the image is large
        int quality = imageBytes.length > 500000 ? 40 : 60;
        int maxWidth = 150;
        
        // Try to fit within Firestore 1MB limit (leaving room for other fields)
        final resizedImage = img.copyResize(decodedImage!, width: maxWidth, height: maxWidth);
        Uint8List jpgImage = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        
        // If still too large, reduce quality and dimensions further
        while (jpgImage.length > 800000 && quality > 10) {
          quality -= 10;
          maxWidth = (maxWidth * 0.9).round(); // Reduce dimensions by 10%
          final smallerImage = img.copyResize(decodedImage, width: maxWidth, height: maxWidth);
          jpgImage = Uint8List.fromList(img.encodeJpg(smallerImage, quality: quality));
        }
        
        // Convert to base64
        final base64Image = base64Encode(jpgImage);
        
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageBase64': base64Image,
        }, SetOptions(merge: true));
        
        // Update locally
        setState(() {
          if (userData == null) userData = {};
          userData!['profileImageBase64'] = base64Image;
        });
      } catch (e) {
        print('Error saving image: $e');
      }
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

  Future<void> logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Clear login timestamp
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('loginTimestamp');

    // Navigate to the Login Page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // Remove all previous routes
    );
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
                onTap: _isUploading ? null : _pickImage, // Disable tapping during upload
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (userData != null && userData?['profileImageBase64'] != null
                              ? MemoryImage(base64Decode(userData!['profileImageBase64']))
                              : AssetImage('assets/images/profile_placeholder.png')) as ImageProvider,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
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
                    await logoutUser(context); // Use the new logoutUser method
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