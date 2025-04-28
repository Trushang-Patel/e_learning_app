import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart'; 
import 'firebase_options.dart';
import 'screens/welcome_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/courses_page.dart';
import 'screens/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Changed from MaterialApp to GetMaterialApp
      debugShowCheckedModeBanner: false,
      title: 'E-Learning App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      getPages: [ // Using Get's route system
        GetPage(name: '/', page: () => LoginPage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
        GetPage(name: '/courses', page: () => CoursesPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
      ],
    );
  }
}