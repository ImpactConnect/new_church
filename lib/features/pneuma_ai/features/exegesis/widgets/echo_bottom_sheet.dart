import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Bottom sheet for displaying full echo details
/// Shows verse text, echo explanation, and CTAs
class EchoBottomSheet extends StatelessWidget {
  final EchoItem echo;
  final String verseText;
  final VoidCallback onOpenInBible;
  final VoidCallback onUnderstandThisVerse;

  const EchoBottomSheet({
    super.key,
    required this.echo,
    required this.verseText,
    required this.onOpenInBible,
    required this.onUnderstandThisVerse,
  });

  static Future<void> show({
    required BuildContext context,
    required EchoItem echo,
    required String verseText,
    required VoidCallback onOpenInBible,
    required VoidCallback onUnderstandThisVerse,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EchoBottomSheet(
        echo: echo,
        verseText: verseText,
        onOpenInBible: onOpenInBible,
        onUnderstandThisVerse: onUnderstandThisVerse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference with connection type dot
                  Row(
                    children: [
                      _buildConnectionDot(echo.connectionType),
                      const SizedBox(width: 8),
                      Text(
                        echo.reference,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4A86A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verse text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      verseText,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 15,
                        height: 1.75,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Echo explanation label
                  Text(
                    'THE CONNECTION',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Echo explanation
                  Text(
                    echo.explanation,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 15,
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTAs
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onOpenInBible();
                          },
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('Open in Bible'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onUnderstandThisVerse();
                          },
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('Understand'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A86A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDot(EchoConnectionType type) {
    Color color;
    switch (type) {
      case EchoConnectionType.parallel:
        color = const Color(0xFF6898D4); // Blue
        break;
      case EchoConnectionType.fulfillment:
        color = const Color(0xFFD4A86A); // Gold
        break;
      case EchoConnectionType.allusion:
        color = const Color(0xFF9878C8); // Purple
        break;
      case EchoConnectionType.contrast:
        color = const Color(0xFFD46A6A); // Red
        break;
      case EchoConnectionType.development:
        color = const Color(0xFF82B882); // Green
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
