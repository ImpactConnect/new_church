import 'package:flutter/material.dart';

/// Bottom sheet for previewing scripture references
/// Shows verse text, relevance note, and action buttons
class ScripturePreviewBottomSheet extends StatelessWidget {
  final String reference;
  final String verseText;
  final String? relevanceNote;
  final Color accentColor;
  final VoidCallback? onOpenInBible;
  final VoidCallback? onRunExegesis;

  const ScripturePreviewBottomSheet({
    super.key,
    required this.reference,
    required this.verseText,
    this.relevanceNote,
    required this.accentColor,
    this.onOpenInBible,
    this.onRunExegesis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Reference
          Text(
            reference,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Verse text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              verseText,
              style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
          
          // Relevance note (if provided)
          if (relevanceNote != null) ...[
            const SizedBox(height: 12),
            Text(
              relevanceNote!,
              style: TextStyle(
                fontFamily: 'Spectral',
                fontSize: 14,
                height: 1.6,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              // Open in Bible button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenInBible,
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Open in Bible'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Run Exegesis button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRunExegesis,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Run Exegesis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
  
  /// Show the scripture preview bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String reference,
    required String verseText,
    String? relevanceNote,
    required Color accentColor,
    VoidCallback? onOpenInBible,
    VoidCallback? onRunExegesis,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScripturePreviewBottomSheet(
        reference: reference,
        verseText: verseText,
        relevanceNote: relevanceNote,
        accentColor: accentColor,
        onOpenInBible: onOpenInBible,
        onRunExegesis: onRunExegesis,
      ),
    );
  }
}
