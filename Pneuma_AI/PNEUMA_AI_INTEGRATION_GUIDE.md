# Pneuma AI Module - Integration & Development Guide

This guide details how to integrate the **Pneuma AI** suite into your new Flutter application. 

**Pneuma AI** serves as the central hub for four primary AI-assisted theological features extracted from the Scripture AI architecture:
1. **Ask Rabbi**: An interactive AI chat focused on scripture questions and localized theological exposition.
2. **ScriptTalk (Speak With)**: A voice-driven interface allowing users to converse with the AI engine.
3. **Exegesis**: An academic-level, in-depth text analysis generator (character, book, chapter, and passage exegesis).
4. **Berean Check**: A theological accuracy and hermeneutical safety checker.

All corresponding files for these features have been securely packaged into the `lib/features/` directory of this extracted module (`exegesis`, `speak_with`, `berean`, and the `bible` AI screens).

---

## 1. Merging the Files

1. Drag and drop the `lib/` and `assets/` folders from this packaged module into the root directory of your new Flutter project.
2. The internal paths (`features/speak_with`, `features/berean`, `features/exegesis`, etc.) will naturally align with the existing architecture.

---

## 2. Pubspec Dependencies

In addition to the core Firebase and Riverpod packages, Pneuma AI requires Text-to-Speech (TTS) capabilities for ScriptTalk. 

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  # Core State and AI
  flutter_riverpod: ^2.6.1
  google_generative_ai: ^0.4.6
  dart_openai: ^5.1.0
  
  # Backend Services
  firebase_core: ^3.8.1
  cloud_firestore: ^5.6.0
  cloud_functions: ^5.6.2
  
  # Pneuma AI Specific
  flutter_tts: ^4.2.5
  go_router: ^14.6.2
```

---

## 3. Creating the "Pneuma AI" Hub Screen

To unify these features, you should create a central "Pneuma AI" menu in your new app. 
You can create a file `lib/features/pneuma_ai/screens/pneuma_ai_hub_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PneumaAiHubScreen extends StatelessWidget {
  const PneumaAiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pneuma AI'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            title: 'Ask Rabbi',
            subtitle: 'Get answers to deep theological questions',
            icon: Icons.chat_bubble_outline,
            route: '/pneuma/ask-rabbi',
          ),
          _buildFeatureCard(
            context,
            title: 'ScriptTalk',
            subtitle: 'Voice converse with biblical intelligence',
            icon: Icons.mic_none,
            route: '/pneuma/script-talk',
          ),
          _buildFeatureCard(
            context,
            title: 'Exegesis Engine',
            subtitle: 'Deep dive into historical and literary context',
            icon: Icons.menu_book,
            route: '/pneuma/exegesis',
          ),
          _buildFeatureCard(
            context,
            title: 'Berean Check',
            subtitle: 'Verify the theological integrity of teachings',
            icon: Icons.fact_check_outlined,
            route: '/pneuma/berean',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String route}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          child: Icon(icon, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.push(route),
      ),
    );
  }
}
```

---

## 4. Configuring GoRouter Logic

In your main router configuration, map the routes to the packaged screens that were brought over in this module.

```dart
final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ... your other app routes
    
    GoRoute(
      path: '/pneuma',
      builder: (context, state) => const PneumaAiHubScreen(),
      routes: [
        GoRoute(
          path: 'ask-rabbi',
          // Maps to the Rabbi UI from the bible screens folder
          builder: (context, state) => const RabbiIntroScreen(), 
        ),
        GoRoute(
          path: 'script-talk',
          // Maps to the speak_with feature
          builder: (context, state) => const SpeakWithScreen(), 
        ),
        GoRoute(
          path: 'exegesis',
          // Maps to the Exegesis hub
          builder: (context, state) => const ExegesisScreen(), 
        ),
        GoRoute(
          path: 'berean',
          // Maps to the Berean check screen
          builder: (context, state) => const BereanCheckScreen(), 
        ),
      ],
    ),
  ],
);
```

---

## 5. System Prompts & Firestore Requirements

All four features rely on the central `AiService` and `PromptRepository` (packaged in `lib/data/repositories/`). 

### Critical Setup Steps:
1. Ensure your new Firebase project has the Remote Config or Firestore collections that the `PromptRepository` expects to fetch system prompts.
2. If Firebase is offline, the features have built-in hardcoded fallback prompts (e.g., inside `verse_ai_service.dart` and `ai_service.dart`), but for real-time tweaking, you should populate your Firestore with the prompts found in `berean_check_prompts.md` and `exegesis-v3-complete-guide.html`.

### API Key Initialization:
Do not forget to initialize the API keys securely when your app starts so `AiConfigService` can route requests to OpenAI/Gemini successfully:

```dart
// Example initialization before accessing Pneuma AI features
await AiConfigService.initialize(
  provider: 'openai', // or 'gemini'
  apiKey: 'YOUR_SECURE_API_KEY',
  model: 'gpt-4o',
);
```

By following this guide, the entire Pneuma AI suite will seamlessly inject into your new application's ecosystem.
