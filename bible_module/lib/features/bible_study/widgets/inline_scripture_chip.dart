import 'package:flutter/material.dart';

/// Inline tappable scripture reference chip.
/// [accentColor] and [onTap] are optional — the chip can be used
/// purely as a reference label without interaction.
class InlineScriptureChip extends StatelessWidget {
  final String reference;
  final Color? accentColor;
  final VoidCallback? onTap;

  const InlineScriptureChip({
    super.key,
    required this.reference,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = accentColor ?? const Color(0xFF5B8DEF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          reference,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: chipColor,
          ),
        ),
      ),
    );
  }
}
