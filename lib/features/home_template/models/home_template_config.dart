import 'package:cloud_firestore/cloud_firestore.dart';

/// The active homepage template configuration stored in:
/// `app_settings/ui_config` → field `activeHomeTemplate`
///
/// Template configs are in:
/// `home_templates/{templateId}` → fields: name, description, bottomNavItems[]
class HomeTemplateConfig {
  final String id;
  final String name;
  final String description;
  final List<BottomNavItemConfig> bottomNavItems;
  final bool isActive;

  const HomeTemplateConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.bottomNavItems,
    this.isActive = true,
  });

  factory HomeTemplateConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final navItems = (data['bottomNavItems'] as List<dynamic>?)
            ?.map((e) =>
                BottomNavItemConfig.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    return HomeTemplateConfig(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      description: data['description'] as String? ?? '',
      bottomNavItems: navItems,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class BottomNavItemConfig {
  final String label;
  final String icon; // Material icon name
  final String route; // named route

  const BottomNavItemConfig({
    required this.label,
    required this.icon,
    required this.route,
  });

  factory BottomNavItemConfig.fromMap(Map<String, dynamic> map) {
    return BottomNavItemConfig(
      label: map['label'] as String? ?? '',
      icon: map['icon'] as String? ?? 'home',
      route: map['route'] as String? ?? '/home',
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'icon': icon,
        'route': route,
      };
}

/// Known template identifiers
class HomeTemplateId {
  HomeTemplateId._();
  static const String classic = 'classic'; // current grid-based home
  static const String bannerCards = 'banner_cards'; // T30-style stacked tiles
  static const String modernFeed = 'modern_feed'; // 3rd template placeholder
}
