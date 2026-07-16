import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/home_tile_model.dart';
import '../repositories/home_template_repository.dart';
import '../widgets/banner_style_tile_card.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../screens/global_search_screen.dart';
import '../../../services/community_auth_service.dart';
import '../../../screens/community/community_login_screen.dart';
import '../../../screens/members/members_directory_screen.dart';
import '../../../screens/full_player_screen.dart';
import '../../../main.dart';

/// The "Banner Style" homepage layout.
/// Renders:
///  • A dark app bar with the church logo and icons
///  • An auto-playing hero carousel at the top
///  • A vertical list of large, rounded, stacked image banners
class BannerStyleHomePage extends StatelessWidget {
  const BannerStyleHomePage({super.key});

  static const String _templateId = 'banner_style';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<HomeTileModel>>(
        stream: HomeTemplateRepository.instance.tilesStream(_templateId),
        builder: (context, snap) {
          final tiles = snap.data ?? [];
          return CustomScrollView(
            slivers: [
              _BannerStyleAppBar(),
              // Hero Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _HeroCarousel(),
                ),
              ),
              // Admin-configured banner tiles
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => BannerStyleTileCard(
                    tile: tiles[i],
                    onTap: () => _handleTileTap(context, tiles[i].route),
                  ),
                  childCount: tiles.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }

  void _handleTileTap(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────
class _BannerStyleAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final fg = isDark ? Colors.white : Colors.black;

    return SliverAppBar(
      pinned: true,
      backgroundColor: bg,
      surfaceTintColor: bg,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16,
      title: Image.asset(
        'assets/images/logo.png',
        height: 36,
        fit: BoxFit.contain,
        color: isDark ? Colors.white : null,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.bar_chart, color: fg),
          onPressed: () {
            final sermon = MyApp.of(context).audioPlayerService.currentSermon;
            if (sermon != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => FullPlayerScreen(
                  sermon: sermon,
                  audioPlayerService: MyApp.of(context).audioPlayerService,
                ),
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No audio currently playing')),
              );
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: fg),
          onPressed: () async {
            final authService = CommunityAuthService();
            final currentUser = await authService.getCurrentUser();
            if (context.mounted) {
              if (currentUser != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersDirectoryScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CommunityLoginScreen(
                    onLoginSuccess: (user) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MembersDirectoryScreen()));
                    },
                  ),
                ));
              }
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.search, color: fg),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle_outlined, color: fg),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Hero Carousel ─────────────────────────────────────────────────────────────
class _HeroCarousel extends StatefulWidget {
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final PageController _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carousel_items')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: SizedBox.shrink()));
        }

        return SizedBox(
          height: 240,
          child: Stack(
            children: [
              PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] as String? ?? '';
                  final targetRoute = data['route'] as String?;
                  
                  return GestureDetector(
                    onTap: () {
                      if (targetRoute != null && targetRoute.isNotEmpty) {
                        Navigator.of(context).pushNamed(targetRoute);
                      }
                    },
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheHeight: 600,
                      placeholder: (_, __) => Container(color: Theme.of(context).scaffoldBackgroundColor),
                      errorWidget: (_, __, ___) => Container(color: Theme.of(context).cardColor),
                    ),
                  );
                },
              ),
              // Dots indicator
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    docs.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
