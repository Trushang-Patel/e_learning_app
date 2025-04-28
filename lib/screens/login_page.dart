import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'courses_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> loginUser(BuildContext context) async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password cannot be empty';
        _isLoading = false;
      });
      return;
    }
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      
      // Store login timestamp
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);

      // Navigate to the Courses Page and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CoursesPage()),
        (route) => false, // Remove all previous routes
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        // Provide user-friendly error messages
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            _errorMessage = 'Wrong password provided';
            break;
          case 'invalid-email':
            _errorMessage = 'Invalid email format';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled';
            break;
          default:
            _errorMessage = 'Login failed: ${e.message}';
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
      
      // Store login timestamp
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
      
      Get.offAll(() => CoursesPage());
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
      
      // Store login timestamp
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
      
      Get.offAll(() => CoursesPage());
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
        title: Text('Login'),
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
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Login to continue learning',
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
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : () => loginUser(context),
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
                      'Login',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
              SizedBox(height: 20),
              
              Text(
                'Or login with',
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
              
              // Register Navigation
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  'Don\'t have an account? Register',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}