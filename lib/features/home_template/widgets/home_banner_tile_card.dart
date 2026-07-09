import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/home_tile_model.dart';

/// A single banner-style tile card used in the "T30" / Banner Cards template.
/// The visual is driven by [HomeTileModel.layoutStyle].
class HomeBannerTileCard extends StatelessWidget {
  const HomeBannerTileCard({
    super.key,
    required this.tile,
    required this.onTap,
  });

  final HomeTileModel tile;
  final VoidCallback onTap;

  static const double _height = 140.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            // Base tile content (Overlay, SplitLeft, SplitRight)
            Positioned.fill(
              child: _buildContent(),
            ),
            
            // Absolute positioned button
            if (tile.actionLabel != null)
              Align(
                alignment: _getButtonAlignment(tile.buttonAlignment),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _CTAButton(label: tile.actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Alignment _getButtonAlignment(String align) {
    switch (align) {
      case 'center': return Alignment.center;
      case 'bottomRight': return Alignment.bottomRight;
      case 'bottomLeft': return Alignment.bottomLeft;
      case 'topLeft': return Alignment.topLeft;
      case 'topRight': return Alignment.topRight;
      default: return Alignment.bottomLeft;
    }
  }

  Widget _buildContent() {
    switch (tile.layoutStyle) {
      case TileLayoutStyle.splitLeft:
        return _SplitLeftTile(tile: tile);
      case TileLayoutStyle.splitRight:
        return _SplitRightTile(tile: tile);
      case TileLayoutStyle.standard:
        return _OverlayTile(tile: tile);
    }
  }
}

// ─── Standard Overlay Tile ────────────────────────────────────────────────────
// Full-bleed image with gradient + text overlaid (e.g., "Live Devotion" tile)
class _OverlayTile extends StatelessWidget {
  const _OverlayTile({required this.tile});
  final HomeTileModel tile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        _BackgroundImage(imageUrl: tile.imageUrl, color: _parseHex(tile.backgroundColorHex, const Color(0xFF2A2A2A))),
        // Gradient
        if (tile.showGradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_parseHex(tile.backgroundColorHex, Colors.black87), Colors.transparent],
                begin: _getAlignment(tile.gradientAlignment),
                end: _getOppositeAlignment(tile.gradientAlignment),
              ),
            ),
          ),
        // Text
        Align(
          alignment: _getAlignment(tile.gradientAlignment),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: _getCrossAxisAlignment(tile.gradientAlignment),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tile.showTitle)
                  Text(
                    tile.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
                if (tile.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      tile.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Alignment _getAlignment(String align) {
    switch (align) {
      case 'centerRight': return Alignment.centerRight;
      case 'topCenter': return Alignment.topCenter;
      case 'bottomCenter': return Alignment.bottomCenter;
      case 'center': return Alignment.center;
      case 'centerLeft':
      default:
        return Alignment.centerLeft;
    }
  }

  Alignment _getOppositeAlignment(String align) {
    switch (align) {
      case 'centerRight': return Alignment.centerLeft;
      case 'topCenter': return Alignment.bottomCenter;
      case 'bottomCenter': return Alignment.topCenter;
      case 'center': return Alignment.center;
      case 'centerLeft':
      default:
        return Alignment.centerRight;
    }
  }

  CrossAxisAlignment _getCrossAxisAlignment(String align) {
    if (align == 'centerRight') return CrossAxisAlignment.end;
    if (align == 'topCenter' || align == 'bottomCenter' || align == 'center') return CrossAxisAlignment.center;
    return CrossAxisAlignment.start;
  }
}

// ─── Split Left Tile ──────────────────────────────────────────────────────────
// Text + CTA on left column, image fills the right (e.g. "Read The Devotional")
class _SplitLeftTile extends StatelessWidget {
  const _SplitLeftTile({required this.tile});
  final HomeTileModel tile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: text content
        Expanded(
          flex: 55,
          child: Container(
            color: _parseHex(tile.backgroundColorHex, const Color(0xFF1C1C1C)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tile.showTitle) _buildTitle(),
              ],
            ),
          ),
        ),
        // Right: image
        Expanded(
          flex: 45,
          child: _BackgroundImage(imageUrl: tile.imageUrl, color: _parseHex(tile.backgroundColorHex, const Color(0xFF2A2A2A))),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    // Parse bold prefix: "READ THE T30" → "READ" in accent color
    final parts = tile.title.split(' ');
    if (parts.isEmpty) return Text(tile.title, style: _titleStyle);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${parts.first} ',
            style: _titleStyle.copyWith(color: const Color(0xFFD4A017)),
          ),
          TextSpan(
            text: parts.skip(1).join(' '),
            style: _titleStyle,
          ),
        ],
      ),
    );
  }

  static const _titleStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.15,
    letterSpacing: -0.3,
  );
}

// ─── Split Right Tile ─────────────────────────────────────────────────────────
// Image on the left, text + CTA on the right (e.g. "Support By Giving")
class _SplitRightTile extends StatelessWidget {
  const _SplitRightTile({required this.tile});
  final HomeTileModel tile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: image
        Expanded(
          flex: 45,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black45,
              BlendMode.darken,
            ),
            child: _BackgroundImage(imageUrl: tile.imageUrl, color: _parseHex(tile.backgroundColorHex, const Color(0xFF2A2A2A))),
          ),
        ),
        // Right: text + CTA
        Expanded(
          flex: 55,
          child: Container(
            color: _parseHex(tile.backgroundColorHex, const Color(0xFF1C1C1C)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tile.showTitle) _buildTitle(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final parts = tile.title.split(' ');
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${parts.first} ',
            style: _titleStyle.copyWith(color: const Color(0xFFD4A017)),
          ),
          if (parts.length > 1)
            TextSpan(
              text: parts.skip(1).join(' '),
              style: _titleStyle,
            ),
        ],
      ),
    );
  }

  static const _titleStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.15,
  );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  const _CTAButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.imageUrl, required this.color});
  final String? imageUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(color: color);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: color),
      errorWidget: (_, __, ___) => Container(color: color),
    );
  }
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
