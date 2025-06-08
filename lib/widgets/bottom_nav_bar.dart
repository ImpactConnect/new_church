import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/members/members_connect_screen.dart';
import '../screens/ministers_corner_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/settings_screen.dart';

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
        screen = SermonScreen(
          sermonService: myApp.sermonService,
          audioPlayerService: myApp.audioPlayerService,
        );
        break;
      case 2:
        screen = const MembersConnectScreen();
        break;
      case 3:
        screen = const MinistersCornerScreen();
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          tooltip: 'Home',
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
          icon: Icon(Icons.person_pin_rounded),
          label: 'Pastor\'s Desk',
          tooltip: 'Pastor\'s Desk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
          tooltip: 'Settings',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      showUnselectedLabels: true,
    );
  }
}
