import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Stub to satisfy import in bible_study_home_screen.dart
// The real implementation is inside study_type_badge.dart
class StudyProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;

  const StudyProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 4,
      ),
    );
  }
}
