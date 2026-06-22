# Scripture Search & Note-Taking Module - Integration Guide

This directory contains the extracted standalone **Search** (including semantic/Bible search) and **Notes** (Rich Text journaling) features from the Scripture AI architecture.

## 1. Folder Structure Merge

Drag and drop the `lib/` folder from this package into the root `lib/` directory of your new Flutter project. 
This will merge the following directories without breaking internal relative paths:
*   `lib/features/search/` (Contains the `SearchScreen` and semantic search widgets)
*   `lib/features/notes/` (Contains the Rich Text Editor, domain logic, and presentation screens)
*   `lib/data/models/notes/` (Contains `note_model.dart` and its generated freezed/json serializers)

---

## 2. Pubspec Dependencies

The Note-taking feature is powered by a robust rich-text editor, and both features rely on Riverpod for state management. 

Add these specific dependencies to your new app's `pubspec.yaml`:

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Data Modeling & Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  equatable: ^2.0.5
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # Rich Text Editor (Critical for Notes feature)
  flutter_quill: ^11.5.0
  
  # Routing
  go_router: ^14.6.2
```

Add these to your `dev_dependencies`:

```yaml
dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  hive_generator: ^2.0.1
```

---

## 3. Code Generation (Crucial Step)

Because the Notes feature utilizes immutable models (`note_model.dart`) and Riverpod providers, you MUST regenerate the `.g.dart` files in your new environment.

Run this command in your terminal:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 4. Hive Local Storage Initialization

The Notes feature likely relies on local storage (Hive) for offline access. Ensure you initialize Hive in your `main.dart` before running the app:

```dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage for Notes
  await Hive.initFlutter();
  // Register adapters if you generated them
  // Hive.registerAdapter(NoteModelAdapter()); 
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 5. Integrating with GoRouter

You can integrate the Search and Note-taking screens directly into your navigation tree. Here is an example setup for GoRouter:

```dart
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    // ... other routes
    
    // Search Feature
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(), // From features/search/screens/
    ),
    
    // Notes Feature
    GoRoute(
      path: '/notes',
      // Point this to the main notes dashboard/list screen
      builder: (context, state) => const NotesListScreen(), 
      routes: [
        GoRoute(
          path: 'editor',
          builder: (context, state) {
            // Optional: Pass an existing note ID to edit, or null for a new note
            final noteId = state.uri.queryParameters['id'];
            return NoteEditorScreen(noteId: noteId); 
          },
        ),
      ],
    ),
  ],
);
```

## 6. Utilizing Semantic Search

If the `SearchScreen` relies on the AI-powered Semantic Search (from the `ILLUMINE` core), ensure that your `AiService` (from the Bible AI module) is correctly configured and that your Firebase/Firestore prompts are accessible. The search UI typically binds directly to the AI service to fetch verses conceptually.
