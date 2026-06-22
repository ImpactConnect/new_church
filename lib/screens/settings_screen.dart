import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../providers/theme_provider.dart';
import '../services/storage_manager.dart';
import '../services/community_auth_service.dart';
import '../models/community_user.dart';
import '../screens/community/community_login_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appSize = '...';
  String _cacheSize = '...';
  bool _isLoading = true;
  bool _isLoggedIn = false;
  CommunityUser? _currentUser;
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await CommunityAuthService().isUserLoggedIn();
    CommunityUser? user;
    if (isLoggedIn) {
      user = await CommunityAuthService().getCurrentUser();
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _currentUser = user;
      });
    }
  }

  Future<void> _loadInfo() async {
    final storageInfo = await StorageManager.getStorageInfo();
    if (mounted) {
      setState(() {
        _appSize = StorageManager.formatSize(storageInfo['appSize']!);
        _cacheSize = StorageManager.formatSize(storageInfo['cacheSize']!);
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data. Downloaded content will not be affected. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageManager.clearCache();
      await _loadInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).primaryColor;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 4),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    _buildProfileHeader(isDark, accentColor),

                    // Appearance Settings
                    _buildCardSection(
                      title: 'PREFERENCES',
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6366F1)),
                          ),
                          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text('Toggle dark theme', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          trailing: Switch.adaptive(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            activeColor: accentColor,
                            onChanged: (value) => themeProvider.toggleTheme(),
                          ),
                        ),
                      ],
                    ),

                    // Storage Settings
                    _buildCardSection(
                      title: 'STORAGE & DATA',
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storage_outlined, color: Color(0xFFF59E0B)),
                          ),
                          title: const Text('App Storage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: Text(_appSize, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                        ),
                        const Divider(height: 1, indent: 64),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cached_outlined, color: Color(0xFF10B981)),
                          ),
                          title: const Text('Cache Size', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text(_cacheSize, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          trailing: TextButton(
                            onPressed: _showClearCacheDialog,
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            child: const Text('CLEAR'),
                          ),
                        ),
                      ],
                    ),

                    // Help & Support Settings
                    _buildCardSection(
                      title: 'HELP & SUPPORT',
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.help_outline_outlined, color: Color(0xFF8B5CF6)),
                          ),
                          title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 64),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.mail_outline_outlined, color: Color(0xFF06B6D4)),
                          ),
                          title: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _launchURL('mailto:support@yourchurch.com'),
                        ),
                      ],
                    ),

                    // About Settings
                    _buildCardSection(
                      title: 'ABOUT',
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                          ),
                          title: const Text('About Application', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text('Version $_appVersion', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1, indent: 64),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.policy_outlined, color: Color(0xFFEF4444)),
                          ),
                          title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _launchURL('https://yourchurch.com/privacy'),
                        ),

                        const Divider(height: 1, indent: 64),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description_outlined, color: Colors.grey),
                          ),
                          title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _launchURL('https://yourchurch.com/terms'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color accentColor) {
    if (_isLoggedIn && _currentUser != null) {
      final name = _currentUser!.displayName;
      final username = _currentUser!.username;
      final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 2,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Theme.of(context).cardColor,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showSignOutDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 2,
        color: Colors.blue.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_circle_outlined, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Guest',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sign in to access all community features',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CommunityLoginScreen()),
                  ).then((_) => _checkLoginStatus());
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In to Your Account', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  shadowColor: accentColor.withOpacity(0.25),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCardSection({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              letterSpacing: 1.5,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: isDark ? 0 : 1,
          color: Theme.of(context).cardColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CommunityAuthService().signOut();
      await FirebaseAuth.instance.signOut();
      await _checkLoginStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Impact Connect',
        applicationVersion: 'Version $_appVersion',
        applicationIcon: const Icon(Icons.church, size: 50, color: Colors.blue),
        children: const [
          Text(
            'Impact Connect is your comprehensive church companion app, '
            'designed to enhance your spiritual journey with features like '
            'Bible study, sermons, events, and more.',
          ),
        ],
      ),
    );
  }
}
