import 'package:flutter/material.dart';
import '../models/bible_study_models.dart';

/// Widget to display session role badges with color-coding
class SessionRoleBadge extends StatelessWidget {
  final SessionRole role;
  final bool small;

  const SessionRoleBadge({
    super.key,
    required this.role,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(role);
    
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        boxShadow: [
          BoxShadow(
            color: config.gradientColors.first.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config.emoji,
            style: TextStyle(fontSize: small ? 10 : 12),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: small ? 10 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _RoleConfig _getRoleConfig(SessionRole role) {
    switch (role) {
      case SessionRole.foundation:
        return _RoleConfig(
          label: 'FOUNDATION',
          emoji: '🏗️',
          gradientColors: [const Color(0xFF4F63D2), const Color(0xFF6B7FE8)],
        );
      case SessionRole.development:
        return _RoleConfig(
          label: 'DEVELOPMENT',
          emoji: '🌱',
          gradientColors: [const Color(0xFF00A86B), const Color(0xFF00C97F)],
        );
      case SessionRole.depth:
        return _RoleConfig(
          label: 'DEPTH',
          emoji: '🔍',
          gradientColors: [const Color(0xFF8B3FC0), const Color(0xFFA855D8)],
        );
      case SessionRole.turningPoint:
        return _RoleConfig(
          label: 'TURNING POINT',
          emoji: '⚡',
          gradientColors: [const Color(0xFFFF6B35), const Color(0xFFFF8C5A)],
        );
      case SessionRole.integration:
        return _RoleConfig(
          label: 'INTEGRATION',
          emoji: '🔗',
          gradientColors: [const Color(0xFF5BB8F6), const Color(0xFF7DCBF9)],
        );
      case SessionRole.application:
        return _RoleConfig(
          label: 'APPLICATION',
          emoji: '🎯',
          gradientColors: [const Color(0xFFE63946), const Color(0xFFF15A5A)],
        );
    }
  }
}

class _RoleConfig {
  final String label;
  final String emoji;
  final List<Color> gradientColors;

  _RoleConfig({
    required this.label,
    required this.emoji,
    required this.gradientColors,
  });
}
