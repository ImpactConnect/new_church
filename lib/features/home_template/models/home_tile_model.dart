import 'package:cloud_firestore/cloud_firestore.dart';

/// A single tile card on the "Banner" (T30-style) homepage template.
/// Stored in Firestore: `home_templates/{templateId}/tiles/{tileId}`
class HomeTileModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? backgroundColorHex; // e.g. "#FF0000" for a solid background
  final String? actionLabel; // e.g. "STUDY", "GIVE", "WATCH"
  final String route; // named route e.g. '/devotional'
  final int sortOrder;
  final bool isActive;
  final TileLayoutStyle layoutStyle;
  final bool showTitle;
  final bool showGradient;
  final String gradientAlignment;
  final String buttonAlignment;
  final bool showExternalText;
  final String? externalText;

  const HomeTileModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.backgroundColorHex,
    this.actionLabel,
    required this.route,
    required this.sortOrder,
    this.isActive = true,
    this.layoutStyle = TileLayoutStyle.standard,
    this.showTitle = true,
    this.showGradient = true,
    this.gradientAlignment = 'centerLeft',
    this.buttonAlignment = 'bottomLeft',
    this.showExternalText = false,
    this.externalText,
  });

  factory HomeTileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeTileModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      imageUrl: data['imageUrl'] as String?,
      backgroundColorHex: data['backgroundColorHex'] as String?,
      actionLabel: data['actionLabel'] as String?,
      route: data['route'] as String? ?? '/home',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      layoutStyle: TileLayoutStyle.fromString(data['layoutStyle'] as String?),
      showTitle: data['showTitle'] as bool? ?? true,
      showGradient: data['showGradient'] as bool? ?? true,
      gradientAlignment: data['gradientAlignment'] as String? ?? 'centerLeft',
      buttonAlignment: data['buttonAlignment'] as String? ?? 'bottomLeft',
      showExternalText: data['showExternalText'] as bool? ?? false,
      externalText: data['externalText'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'backgroundColorHex': backgroundColorHex,
        'actionLabel': actionLabel,
        'route': route,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'layoutStyle': layoutStyle.value,
        'showTitle': showTitle,
        'showGradient': showGradient,
        'gradientAlignment': gradientAlignment,
        'buttonAlignment': buttonAlignment,
        'showExternalText': showExternalText,
        'externalText': externalText,
      };

  HomeTileModel copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    String? backgroundColorHex,
    String? actionLabel,
    String? route,
    int? sortOrder,
    bool? isActive,
    TileLayoutStyle? layoutStyle,
    bool? showTitle,
    bool? showGradient,
    String? gradientAlignment,
    String? buttonAlignment,
    bool? showExternalText,
    String? externalText,
  }) {
    return HomeTileModel(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      actionLabel: actionLabel ?? this.actionLabel,
      route: route ?? this.route,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      showTitle: showTitle ?? this.showTitle,
      showGradient: showGradient ?? this.showGradient,
      gradientAlignment: gradientAlignment ?? this.gradientAlignment,
      buttonAlignment: buttonAlignment ?? this.buttonAlignment,
      showExternalText: showExternalText ?? this.showExternalText,
      externalText: externalText ?? this.externalText,
    );
  }
}

/// Controls how a tile renders its text / CTA positioning.
enum TileLayoutStyle {
  standard, // text left, CTA left (like "Live Devotion")
  splitLeft, // text+cta left, image right (like "Read The Devotional")
  splitRight; // text left, cta right (like "Support By Giving")

  static TileLayoutStyle fromString(String? value) {
    switch (value) {
      case 'splitLeft':
        return TileLayoutStyle.splitLeft;
      case 'splitRight':
        return TileLayoutStyle.splitRight;
      default:
        return TileLayoutStyle.standard;
    }
  }

  String get value {
    switch (this) {
      case TileLayoutStyle.splitLeft:
        return 'splitLeft';
      case TileLayoutStyle.splitRight:
        return 'splitRight';
      case TileLayoutStyle.standard:
        return 'standard';
    }
  }

  String get label {
    switch (this) {
      case TileLayoutStyle.splitLeft:
        return 'Text Left / Image Right';
      case TileLayoutStyle.splitRight:
        return 'Image Left / Text Right';
      case TileLayoutStyle.standard:
        return 'Standard (Overlay)';
    }
  }
}
