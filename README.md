# Impact Connect - Church Mobile App

## Overview
Impact Connect is a modern mobile application built with Flutter, designed to serve as a comprehensive church community platform. The app combines multimedia content, authentication, and storage capabilities to create an engaging experience for church members.

## Features

### 🎵 Audio Features
- Integrated audio playback system
- Background audio support
- Audio session management for seamless experience

### 🔐 Authentication & Security
- Secure user authentication via Firebase Auth
- User profile management
- Protected content access

### 💾 Data Management
- Cloud-based storage using Firebase Storage
- Real-time data synchronization with Cloud Firestore
- Efficient local data caching

### 📱 User Experience
- Modern and intuitive UI with Material Design
- Dark mode support
- Responsive layout for various screen sizes
- Web content integration via WebView

### 🔔 Additional Features
- Push notifications support
- File handling and management
- URL handling capabilities
- Permission management system

## Technical Stack

### Core Framework
- Flutter SDK
- Dart programming language

### Backend Services
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Analytics

### Key Dependencies
- audio_service: For background audio playback
- audio_session: For audio session management
- just_audio: For audio playback functionality
- firebase_core: Firebase core functionality
- firebase_auth: Authentication services
- cloud_firestore: Cloud database
- firebase_storage: File storage
- webview_flutter: Web content display
- shared_preferences: Local data storage
- path_provider: File system access
- permission_handler: Device permissions
- url_launcher: External URL handling

## Platform Support
- Android (SDK 23+)
- Optimized for Android SDK 35

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- Firebase project setup

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase credentials
4. Run the app using `flutter run`

### Building Release Version
```bash
flutter build apk --release
```

## Development Notes
- Kotlin version: 2.1.0
- Minimum Android SDK: 23
- Target Android SDK: 35
- ProGuard rules enabled for release builds
- MultiDex enabled

## License
This project is proprietary and confidential.

## Support
For support and inquiries, please contact the development team.
