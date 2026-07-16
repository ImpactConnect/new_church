import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/home_tile_model.dart';

/// A banner-style tile card used in the "Banner Style" template.
class BannerStyleTileCard extends StatelessWidget {
  const BannerStyleTileCard({
    super.key,
    required this.tile,
    required this.onTap,
  });

  final HomeTileModel tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220.0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (tile.imageUrl != null && tile.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tile.imageUrl!,
                fit: BoxFit.cover,
                memCacheHeight: 600, // memory optimization
                placeholder: (_, __) => Container(color: _parseHex(tile.backgroundColorHex, Theme.of(context).cardColor)),
                errorWidget: (_, __, ___) => Container(color: _parseHex(tile.backgroundColorHex, Theme.of(context).cardColor)),
              )
            else
              Container(color: _parseHex(tile.backgroundColorHex, Theme.of(context).cardColor)),
            
            // Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),

            // Decorative stars (optional, matching design)
            const Positioned(
              top: 16,
              left: 16,
              child: Icon(Icons.star_border, color: Colors.white54, size: 24),
            ),
            const Positioned(
              bottom: 16,
              right: 16,
              child: Icon(Icons.star_border, color: Colors.white54, size: 24),
            ),

            // Centered Text
            if (tile.showTitle)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    tile.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Subtitle
            if (tile.subtitle != null && tile.subtitle!.isNotEmpty)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Text(
                  tile.subtitle!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseHex(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.trim().isEmpty) return defaultColor;
    var hex = hexString.trim().toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    int? val = int.tryParse(hex, radix: 16);
    return val != null ? Color(val) : defaultColor;
  }
}
