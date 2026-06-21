import 'package:flutter/material.dart';
import '../features/bible_ai/features/bible/screens/bible_home_screen.dart';

/// Entry point for the Bible AI (ILLUMINE) feature from the church app.
/// This is a thin wrapper that composes cleanly with the existing navigation.
class BibleAiEntryScreen extends StatelessWidget {
  const BibleAiEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => const BibleHomeScreen();
}
