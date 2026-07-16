import 'package:flutter/material.dart';
import '../../../main.dart';
import 'banner_cards_home_page.dart';
import 'modern_feed_home_page.dart';
import '../models/home_template_config.dart';
import '../repositories/home_template_repository.dart';

/// Root switcher widget. This replaces [HomePage] as the entry point.
/// It listens to Firestore in real-time and renders the correct template.
class HomeTemplateSwitcher extends StatelessWidget {
  const HomeTemplateSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: HomeTemplateRepository.instance.activeTemplateIdStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final templateId = snap.data ?? HomeTemplateId.classic;

        switch (templateId) {
          case HomeTemplateId.bannerCards:
            return const BannerCardsHomePage();
          case HomeTemplateId.modernFeed:
            return const ModernFeedHomePage();
          case HomeTemplateId.classic:
          default:
            return const HomePage();
        }
      },
    );
  }
}
