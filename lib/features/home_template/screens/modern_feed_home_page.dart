import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav_bar.dart';

/// The 3rd homepage template.
/// This is a placeholder for a new "Modern Feed" style layout.
class ModernFeedHomePage extends StatelessWidget {
  const ModernFeedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Feed'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Template 3: Modern Feed\n(Under Construction)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
