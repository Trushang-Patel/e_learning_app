import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> registerUser(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      print('Email and password cannot be empty');
      return;
    }
    if (passwordController.text.length < 6) {
      print('Password should be at least 6 characters');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      print('Passwords do not match');
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print('Registration successful');
      // Navigate to the Login Page
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light background color
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Colors.blueAccent, // AppBar color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // App Logo
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/logo.jpg'), // Add your logo here
              ),
              SizedBox(height: 20),
              Text(
                'Create an Account!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Join us and start learning today',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 30),
              // Email TextField
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              // Password TextField
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Confirm Password TextField
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Register Button
              ElevatedButton(
                onPressed: () => registerUser(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Or register with',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              // Google and GitHub Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Login Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle Google login logic
                      print('Google Login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png', // Add Google logo here
                      height: 20,
                    ),
                    label: Text(
                      'Google',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(width: 10),
                  // GitHub Login Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle GitHub login logic
                      print('GitHub Login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.code,
                      color: Colors.white,
                    ),
                    label: Text(
                      'GitHub',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Login Navigation
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Navigate back to login page
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}