import 'package:flutter/material.dart';

/// Visual separator for Go Deep technical content
/// 
/// Design specs:
/// - Horizontal line with centered label
/// - Label: "↓ DEEPER LAYER" (10sp mono)
/// - Blue tint background shift
/// - Appears after SomethingToSitWithCard
/// - Only visible in Go Deep mode
class DeeperLayerDivider extends StatelessWidget {
  final bool visible;

  const DeeperLayerDivider({
    super.key,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    const goDeepBlue = Color(0xFF6898D4);
    final backgroundColor = isDark
        ? goDeepBlue.withOpacity(0.08)
        : goDeepBlue.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: goDeepBlue.withOpacity(0.2),
            width: 1,
          ),
          bottom: BorderSide(
            color: goDeepBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: goDeepBlue.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '↓ DEEPER LAYER',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: goDeepBlue,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: goDeepBlue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
