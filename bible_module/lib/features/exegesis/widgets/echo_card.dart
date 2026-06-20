import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Card displaying a cross-reference as a narrative connection (echo)
/// 
/// Design specs:
/// - Reference: Amber mono (JetBrains Mono 11sp)
/// - Connection dot: Color-coded by type (no label)
///   - Parallel: Blue
///   - Fulfillment: Gold
///   - Allusion: Purple
///   - Contrast: Red
///   - Development: Green
/// - Echo explanation: 13sp Spectral body
/// - Subtle border, rounded corners
/// 
/// Interaction:
/// - Tap opens EchoBottomSheet with full verse text and actions
class EchoCard extends StatelessWidget {
  final EchoItem echo;
  final VoidCallback onTap;

  const EchoCard({
    super.key,
    required this.echo,
    required this.onTap,
  });

  Color _getConnectionColor(EchoConnectionType type) {
    switch (type) {
      case EchoConnectionType.parallel:
        return const Color(0xFF6898D4); // Blue
      case EchoConnectionType.fulfillment:
        return const Color(0xFFD4A86A); // Gold
      case EchoConnectionType.allusion:
        return const Color(0xFF9878C8); // Purple
      case EchoConnectionType.contrast:
        return const Color(0xFFD46A6A); // Red
      case EchoConnectionType.development:
        return const Color(0xFF82B882); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final connectionColor = _getConnectionColor(echo.connectionType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection type dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                color: connectionColor,
                shape: BoxShape.circle,
              ),
            ),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference
                  Text(
                    echo.reference,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: const Color(0xFFD4A86A), // Amber
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Echo explanation
                  Text(
                    echo.explanation,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron indicator
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
