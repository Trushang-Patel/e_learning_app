# E-Learning App

An E-Learning application built with Flutter and Firebase. This app allows users to register, log in, view available courses, and provides an admin panel for managing courses.

---

## Features

- **User Authentication**:
  - Register and log in using email and password.
  - Firebase Authentication integration.

- **Course Management**:
  - Users can view a list of available courses.
  - Admins can add and remove courses.

- **Admin Panel**:
  - Restricted access for admin users to manage courses.

---

## Screens

1. **Welcome Page**: Introduction to the app.
2. **Login Page**: Allows users to log in.
3. **Register Page**: Allows new users to register.
4. **Courses Page**: Displays a list of available courses.
5. **Admin Panel**: Allows the admin to add or remove courses.

---

## Firebase Configuration

1. Set up a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Email/Password Authentication** under **Authentication > Sign-in method**.
3. Add a **Firestore Database** and set the security rules to allow admin-only write access.
4. Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files and place them in the appropriate directories:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Run `flutterfire configure` to generate the `firebase_options.dart` file.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Trushang-Patel/e_learning_app.git
   cd e_learning_app
   ```
2. Install dependencies:
    ```bash
    flutter pub get
    ```
3. Run the app:
    ```bash
    flutter run
    ```

# Dependencies
The following packages are used in this project:

firebase_core: For initializing Firebase.
firebase_auth: For user authentication.
cloud_firestore: For managing course data.
google_sign_in: For Google authentication (optional).
cupertino_icons: For iOS-style icons.

# Folder Structure

e_learning_app/
├── lib/
│   ├── main.dart                # Entry point of the app
│   ├── screens/
│   │   ├── welcome_page.dart    # Welcome screen
│   │   ├── login_page.dart      # Login screen
│   │   ├── register_page.dart   # Registration screen
│   │   ├── courses_page.dart    # Courses screen
│   │   ├── admin_page.dart      # Admin panel
│   └── firebase_options.dart    # Firebase configuration (auto-generated)
├── android/                     # Android-specific files
├── ios/                         # iOS-specific files
├── [pubspec.yaml](http://_vscodecontentref_/1)                 # Project dependencies
└── [README.md](http://_vscodecontentref_/2)                    # Project documentation