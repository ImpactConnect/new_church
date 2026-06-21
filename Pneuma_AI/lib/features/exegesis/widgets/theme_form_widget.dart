import 'package:flutter/material.dart';

/// Form widget for Theme entry type
/// Multi-line topic field with suggestion chips
class ThemeFormWidget extends StatefulWidget {
  final ValueChanged<bool> onValidityChanged;

  const ThemeFormWidget({
    super.key,
    required this.onValidityChanged,
  });

  @override
  State<ThemeFormWidget> createState() => ThemeFormWidgetState();
}

// Make the state class public so it can be accessed via GlobalKey
class ThemeFormWidgetState extends State<ThemeFormWidget> {
  String? _topic;
  String? _specificAngle;

  static const List<String> _popularThemes = [
    'Faith',
    'Grace',
    'Covenant',
    'Redemption',
    'Love',
    'Justice',
    'Mercy',
    'Hope',
    'Salvation',
    'Kingdom of God',
    'Righteousness',
    'Holiness',
  ];

  /// Public method to get form data
  Map<String, dynamic> getFormData() {
    return {
      'topic': _topic ?? '',
      'specificAngle': _specificAngle,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  void _validateForm() {
    widget.onValidityChanged(
      _topic != null && _topic!.trim().isNotEmpty,
    );
  }

  void _selectSuggestion(String theme) {
    setState(() {
      _topic = theme;
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic field
        Text(
          'Theme or Topic',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., The concept of grace in Scripture',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _topic = value.isEmpty ? null : value;
              _validateForm();
            });
          },
        ),

        const SizedBox(height: 24),

        // Popular themes
        Text(
          'Popular Themes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to use as your theme',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularThemes.map((popularTheme) {
            return GestureDetector(
              onTap: () => _selectSuggestion(popularTheme),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0f1020)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFc84f9a).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  popularTheme,
                  style: TextStyle(
                    color: const Color(0xFFc84f9a),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Specific angle field
        Text(
          'Specific Angle (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., How this theme develops from OT to NT',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _specificAngle = value.isEmpty ? null : value;
            });
          },
        ),

        const SizedBox(height: 24),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFc84f9a).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFc84f9a).withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFFc84f9a),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The study will trace this theme through 8 canonical eras from Genesis to Revelation, showing its development across Scripture.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
