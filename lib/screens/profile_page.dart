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

  Future<void> _deleteAccount(BuildContext context) async {
  // First confirmation dialog
  bool confirmDelete = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Account'),
      content: Text(
        'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        style: TextStyle(color: Colors.red.shade700),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Delete'),
        ),
      ],
    ),
  ) ?? false;

  if (!confirmDelete) return;

  // Second confirmation with password
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Get password for reauthentication
  String? password = await _promptForPassword();
  if (password == null) return; // User canceled

  try {
    // Show loading indicator
    setState(() {
      _isUploading = true; // Reuse the loading state
    });
    
    // Reauthenticate user
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    
    await user.reauthenticateWithCredential(credential);
    
    // Delete user data from Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    
    // Delete user account
    await user.delete();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your account has been deleted successfully.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate to login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    setState(() {
      _isUploading = false;
    });
    
    String errorMessage = 'Failed to delete account.';
    if (e.code == 'wrong-password') {
      errorMessage = 'Incorrect password. Please try again.';
    } else if (e.code == 'too-many-requests') {
      errorMessage = 'Too many attempts. Please try again later.';
    } else if (e.code == 'user-not-found') {
      errorMessage = 'User not found.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    setState(() {
      _isUploading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting account: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<String?> _promptForPassword() async {
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Confirm Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For security reasons, please enter your password to delete your account.',
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter your password'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(passwordController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    ),
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
            SizedBox(height: 40),
            Divider(thickness: 1),
            SizedBox(height: 20),
            Text(
              'Danger Zone',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
                color: Colors.red.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Once you delete your account, there is no going back. Please be certain.',
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUploading ? null : () => _deleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                    child: _isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          )
                        : Text('Delete Account'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}
}