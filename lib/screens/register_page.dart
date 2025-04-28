import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> registerUser(BuildContext context) async {
    // Clear previous error messages and start loading
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate input fields
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password cannot be empty';
        _isLoading = false;
      });
      return;
    }
    
    if (passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password should be at least 6 characters';
        _isLoading = false;
      });
      return;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }
    
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      
      // Show success message before navigating
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Please login.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait a moment to show the success message before navigating
      Future.delayed(Duration(seconds: 1), () {
        // Navigate to the Login Page
        Navigator.pushReplacementNamed(context, '/login');
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        // Provide user-friendly error messages
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'This email is already registered. Please login instead.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address';
            break;
          case 'weak-password':
            _errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Email/password registration is not enabled';
            break;
          default:
            _errorMessage = 'Registration failed: ${e.message}';
            break;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      Navigator.pushReplacementNamed(context, '/courses');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google Sign-In failed: $e';
      });
    }
  }

  Future<void> signInWithGitHub() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    
    try {
      final githubProvider = GithubAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(githubProvider);
      
      Navigator.pushReplacementNamed(context, '/courses');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'GitHub Sign-In failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Colors.blueAccent,
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
                backgroundImage: AssetImage('assets/images/logo.jpg'),
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
              
              // Display error message if any
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: Colors.red[300]),
                        onPressed: () => setState(() => _errorMessage = null),
                      )
                    ],
                  ),
                ),
              
              // Email TextField
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              
              // Password TextField with visibility toggle
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  helperText: 'Password must be at least 6 characters',
                ),
                obscureText: !_isPasswordVisible,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              
              // Confirm Password TextField with visibility toggle
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              SizedBox(height: 24),
              
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : () => registerUser(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.blueAccent.withOpacity(0.6),
                ),
                child: _isLoading 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
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
                    onPressed: _isLoading ? null : signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey),
                      ),
                      disabledBackgroundColor: Colors.white.withOpacity(0.7),
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
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
                    onPressed: _isLoading ? null : signInWithGitHub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.black.withOpacity(0.7),
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
                onPressed: _isLoading ? null : () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}