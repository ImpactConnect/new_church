import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/members/members_connect_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/bible_ai_entry_screen.dart';

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
          builder: (context) => const HomePage(),
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
        currentIndex: currentIndex,
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
  }
}
