import 'package:flutter/material.dart';
import '../main.dart';
import '../features/home_template/screens/home_template_switcher.dart';
import '../screens/members/members_connect_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/bible_ai_entry_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/home_template/models/home_template_config.dart';
import '../features/home_template/repositories/home_template_repository.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  final int currentIndex;

  void _onNavigateHome(BuildContext context) {
    // First try to find HomePage in the widget tree
    bool foundHome = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/') {
        foundHome = true;
        return true;
      }
      return false;
    });

    // If we didn't find HomePage, create a new one
    if (!foundHome) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeTemplateSwitcher(),
          settings: const RouteSettings(name: '/'),
        ),
        (route) => false,
      );
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    final myApp = context.findAncestorWidgetOfExactType<MyApp>();
    if (myApp == null) return;

    if (index == 0) {
      _onNavigateHome(context);
      return;
    }

    // For other screens, replace current screen but keep home in stack
    Widget screen;
    switch (index) {
      case 1:
        screen = const BibleAiEntryScreen();
        break;
      case 2:
        screen = SermonScreen(
          sermonService: myApp.sermonService,
          audioPlayerService: myApp.audioPlayerService,
        );
        break;
      case 3:
        screen = const MembersConnectScreen();
        break;
      case 4:
        screen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (route) => route.settings.name == '/' || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: HomeTemplateRepository.instance.activeTemplateIdStream,
      builder: (context, snap) {
        final activeId = snap.data;
        if (activeId == HomeTemplateId.bannerCards || activeId == HomeTemplateId.bannerStyle) {
          return BannerCardsBottomNav(templateId: activeId!);
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [
                      Color(0xFF1E293B), // Slate 800
                      Color(0xFF0F172A), // Slate 900
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isDark ? null : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex == -1 ? 0 : currentIndex, // fallback if -1
            onTap: (index) => _onItemTapped(context, index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                tooltip: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'AI Bible',
                tooltip: 'AI Bible',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.headphones),
                label: 'Audio',
                tooltip: 'Sermons',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                label: 'Members',
                tooltip: 'Members Connect',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
                tooltip: 'Settings',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            selectedItemColor: isDark ? const Color(0xFF6366F1) : Theme.of(context).primaryColor,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
            showUnselectedLabels: true,
          ),
        );
      },
    );
  }
}

class BannerCardsBottomNav extends StatelessWidget {
  const BannerCardsBottomNav({Key? key, this.templateId = 'banner_cards'}) : super(key: key);

  final String templateId;

  static const _defaultNavItems = [
    {'label': 'Home', 'icon': 'home', 'route': '/home'},
    {'label': 'Bible', 'icon': 'menu_book', 'route': '/bible'},
    {'label': 'Sermons', 'icon': 'headphones', 'route': '/sermons'},
    {'label': 'Members', 'icon': 'people_alt', 'route': '/members'},
    {'label': 'More', 'icon': 'list', 'route': '/settings'},
  ];

  IconData _iconFromName(String name) {
    const iconMap = <String, IconData>{
      'home': Icons.home,
      'menu_book': Icons.menu_book,
      'book': Icons.book,
      'headphones': Icons.headphones,
      'play_circle': Icons.play_circle,
      'people_alt': Icons.people_alt_outlined,
      'settings': Icons.settings,
      'list': Icons.list,
      'diamond': Icons.diamond_outlined,
      'travel_explore': Icons.travel_explore,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[name] ?? Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('home_templates')
          .doc(templateId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final rawItems = data?['bottomNavItems'] as List<dynamic>?;
        final items = rawItems != null && rawItems.isNotEmpty ? rawItems : _defaultNavItems;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
        final fg = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? (isDark ? Colors.white70 : Colors.black54);
        final activeFg = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? (isDark ? Colors.white : Colors.black);

        return Container(
          color: bg,
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i] as Map<String, dynamic>;
                final route = item['route'] as String? ?? '/home';
                final isActive = route == currentRoute;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (route == currentRoute) return;
                      if (route == '/home') {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          route,
                          (r) => r.settings.name == '/' || r.isFirst,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconFromName(item['icon'] as String? ?? 'home'),
                            color: isActive ? activeFg : fg,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String? ?? '',
                            style: TextStyle(
                              color: isActive ? activeFg : fg,
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
