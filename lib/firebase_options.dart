// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBIaucK1MQgJBxDq-YO8J9Xqf4qMsQZzDA',
    appId: '1:12198595037:web:3cd64b3fe32a412740ce34',
    messagingSenderId: '12198595037',
    projectId: 'e-learning-app-8c636',
    authDomain: 'e-learning-app-8c636.firebaseapp.com',
    storageBucket: 'e-learning-app-8c636.firebasestorage.app',
    measurementId: 'G-Z5MDQQ1RKB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3VceWg8u4WtvEL_afxyfswRhEDQY5r58',
    appId: '1:12198595037:android:5d493174f3eaa80e40ce34',
    messagingSenderId: '12198595037',
    projectId: 'e-learning-app-8c636',
    storageBucket: 'e-learning-app-8c636.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2mEF5Vf1P3rAnVapmjp3m7POTiVyq11Q',
    appId: '1:12198595037:ios:cd1f7327e92050db40ce34',
    messagingSenderId: '12198595037',
    projectId: 'e-learning-app-8c636',
    storageBucket: 'e-learning-app-8c636.firebasestorage.app',
    iosClientId: '12198595037-45m8rd3r8l854ij3am22fqni0h8q7e42.apps.googleusercontent.com',
    iosBundleId: 'com.example.eLearningApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC2mEF5Vf1P3rAnVapmjp3m7POTiVyq11Q',
    appId: '1:12198595037:ios:cd1f7327e92050db40ce34',
    messagingSenderId: '12198595037',
    projectId: 'e-learning-app-8c636',
    storageBucket: 'e-learning-app-8c636.firebasestorage.app',
    iosClientId: '12198595037-45m8rd3r8l854ij3am22fqni0h8q7e42.apps.googleusercontent.com',
    iosBundleId: 'com.example.eLearningApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBIaucK1MQgJBxDq-YO8J9Xqf4qMsQZzDA',
    appId: '1:12198595037:web:111632516a428f5040ce34',
    messagingSenderId: '12198595037',
    projectId: 'e-learning-app-8c636',
    authDomain: 'e-learning-app-8c636.firebaseapp.com',
    storageBucket: 'e-learning-app-8c636.firebasestorage.app',
    measurementId: 'G-TLV1T78949',
  );
}
