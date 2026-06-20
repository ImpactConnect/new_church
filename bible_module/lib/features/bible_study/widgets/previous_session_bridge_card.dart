import 'package:flutter/material.dart';

/// Widget to display the Previous Session Bridge at the top of Sessions 2+
/// Shows a warm recap of what was established in previous sessions
class PreviousSessionBridgeCard extends StatelessWidget {
  final String bridgeText;
  final List<int> sessionsReferenced;
  final Color accent;

  const PreviousSessionBridgeCard({
    super.key,
    required this.bridgeText,
    required this.sessionsReferenced,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.12),
            accent.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUING FROM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSessionsLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bridge text
            Text(
              bridgeText,
              style: TextStyle(
                fontSize: 15,
                height: 1.75,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? Colors.white.withOpacity(0.95)
                    : const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSessionsLabel() {
    if (sessionsReferenced.isEmpty) return 'Previous Session';
    if (sessionsReferenced.length == 1) {
      return 'Session ${sessionsReferenced.first}';
    }
    return 'Sessions ${sessionsReferenced.join(', ')}';
  }
}
