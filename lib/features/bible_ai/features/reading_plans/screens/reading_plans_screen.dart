import 'package:flutter/material.dart';

/// Stub reading plans screen — placeholder until full reading plans feature is integrated.
class ReadingPlansScreen extends StatelessWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Plans')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Reading Plans Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'AI-powered reading plans will be available here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
