# ILLUMINE Bible AI Engine - Integration Guide

This directory contains the extracted Bible and AI Engine (ILLUMINE) module from the Scripture AI app. It is structured identically to its original environment to ensure drop-in compatibility for any new Flutter app using Riverpod, Freezed, Firebase, and GoRouter.

## 1. Project Folder Merge

To integrate this module into your new app, merge the contents of this folder with the root of your new Flutter project.

1. Copy the contents of the `lib/` folder from this module and merge them into the `lib/` folder of your new app.
2. Copy the `assets/` folder from this module and merge it into the root of your new app.

*Note: Because the relative imports inside the code (e.g., `import '../../data/models/bible_verse.dart'`) remain unchanged, merging the `lib` folders directly prevents pathing errors.*

## 2. Update `pubspec.yaml`

You must ensure your new app has the same dependencies required to run the AI engine and Bible models.

Add the following to your `dependencies` in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
    
  # State Management & DI
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Firebase Services (Crucial for fallback and prompts)
  firebase_core: ^3.8.1
  cloud_firestore: ^5.6.0
  cloud_functions: ^5.6.2
  
  # Data Modeling
  json_annotation: ^4.9.0
  equatable: ^2.0.5
  freezed_annotation: ^2.4.4
  
  # AI Providers
  dart_openai: ^5.1.0
  google_generative_ai: ^0.4.6
  
  # Routing
  go_router: ^14.6.2
```

Add the following to your `dev_dependencies`:

```yaml
dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
```

Declare the newly copied assets in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/json/
```

Run `flutter pub get` after updating.

## 3. Code Generation

Because the module relies heavily on `freezed` and `riverpod_generator` for models and state, you MUST run the build runner in your new app to generate the `.g.dart` and `.freezed.dart` files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 4. Firebase Configuration

The `AiService` falls back to Firebase Cloud Functions and Firestore for its prompts. 
Ensure you have initialized Firebase in your `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

Make sure your new Firebase project has the necessary Firestore collections for `prompts` (e.g., `explain_verse_explain`, `chat_general`) to override local AI instructions remotely.

## 5. Integrating with GoRouter

The Bible UI screens (like `BibleHomeScreen`, `ChapterScreen`, `VerseAiResultsScreen`) are standard Flutter widgets. You can integrate them into your new app's GoRouter setup like so:

```dart
final router = GoRouter(
  initialLocation: '/bible',
  routes: [
    GoRoute(
      path: '/bible',
      builder: (context, state) => const BibleHomeScreen(),
      routes: [
        GoRoute(
          path: 'chapter/:bookId/:chapterId',
          builder: (context, state) {
            // Extract IDs and pass to your ChapterScreen
            return ChapterScreen(...);
          },
        ),
        GoRoute(
          path: 'ai-results',
          builder: (context, state) {
            // Pass the selected verse and VerseFeature enum
            return VerseAiResultsScreen(...);
          },
        ),
      ]
    ),
  ],
);
```

## 6. Configuring AI Keys

The `AiService` uses `AiConfigService.getApiKey()` to fetch the OpenAI or Gemini API keys. 
In your new app, ensure that `AiConfigService` is properly wired up to either:
1. Fetch the keys from Firestore Remote Config.
2. Fetch them securely from an environment variable (`.env`).

*Do not commit raw API keys to your new repository.*
