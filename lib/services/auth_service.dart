import 'dart:async';

class User {
  final String email;
  final String? displayName;
  final String? photoURL;

  User({required this.email, this.displayName, this.photoURL});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final StreamController<User?> _authController = StreamController<User?>.broadcast();

  User? get currentUser => _currentUser;
  Stream<User?> get authStateChanges => _authController.stream;

  // Email & Password Sign In
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // For testing purposes, accept any credentials but especially these test ones
    if (email == "test@example.com" && password == "password") {
      _currentUser = User(email: email, displayName: "Test User");
    } else {
      _currentUser = User(email: email);
    }
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  // Email & Password Sign Up
  Future<User> registerWithEmailAndPassword(String email, String password, String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = User(email: email, displayName: name);
    _authController.add(_currentUser);
    return _currentUser!;
  }

  // Google Sign In (mock)
  Future<User> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a mock Google user
    _currentUser = User(
      email: "google_user@example.com",
      displayName: "Google User",
      photoURL: "https://via.placeholder.com/150",
    );
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  // Facebook Sign In (mock)
  Future<User> signInWithFacebook() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a mock Facebook user
    _currentUser = User(
      email: "facebook_user@example.com",
      displayName: "Facebook User",
      photoURL: "https://via.placeholder.com/150",
    );
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  // Reset Password (mock)
  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, this would trigger a password reset email
    print('Password reset requested for: $email');
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}