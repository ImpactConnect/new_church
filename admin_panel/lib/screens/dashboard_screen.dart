import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'overview_screen.dart';
import 'live_stream_manager.dart';
import 'sermon_manager.dart';
import 'events_manager.dart';
import 'devotionals_manager.dart';
import 'carousel_manager.dart';
import 'users_manager.dart';
import 'notifications_manager.dart';
import 'media_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    (icon: Icons.dashboard_outlined, label: 'Overview'),
    (icon: Icons.live_tv_outlined, label: 'Live Stream'),
    (icon: Icons.headphones_outlined, label: 'Sermons'),
    (icon: Icons.video_library_outlined, label: 'Videos'),
    (icon: Icons.photo_library_outlined, label: 'Gallery'),
    (icon: Icons.people_outline, label: 'Users'),
    (icon: Icons.event_outlined, label: 'Events'),
    (icon: Icons.menu_book_outlined, label: 'Devotionals'),
    (icon: Icons.view_carousel_outlined, label: 'Banners'),
    (icon: Icons.notifications_outlined, label: 'Alerts'),
  ];

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const OverviewScreen();
      case 1:
        return const LiveStreamManager();
      case 2:
        return const SermonManager();
      case 3:
        return const VideoManager();
      case 4:
        return const GalleryManager();
      case 5:
        return const UsersManager();
      case 6:
        return const EventsManager();
      case 7:
        return const DevotionalsManager();
      case 8:
        return const CarouselManager();
      case 9:
        return const NotificationsManager();
      default:
        return const Center(child: Text('Select an item'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF1A1D2E),
            child: Column(
              children: [
                // Logo / Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 32),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.church,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Impact\nConnect',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    itemCount: _destinations.length,
                    itemBuilder: (context, index) {
                      final dest = _destinations[index];
                      final isSelected = _selectedIndex == index;
                      return _SidebarItem(
                        icon: dest.icon,
                        label: dest.label,
                        isSelected: isSelected,
                        onTap: () =>
                            setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                // Logged in user info + logout
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              (user?.email ?? 'A')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user?.email ?? 'Admin',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.white54, size: 18),
                            tooltip: 'Sign Out',
                            onPressed: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _destinations[_selectedIndex].label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Text('Impact Connect Admin',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                FirebaseAuth.instance.signOut();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.blue.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isSelected ? Colors.blue[300] : Colors.white54,
                    size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
