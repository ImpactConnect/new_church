import 'package:flutter/material.dart';

/// Form widget for Character entry type
/// Free text name field with optional study angle chips
class CharacterFormWidget extends StatefulWidget {
  final ValueChanged<bool> onValidityChanged;

  const CharacterFormWidget({
    super.key,
    required this.onValidityChanged,
  });

  @override
  State<CharacterFormWidget> createState() => CharacterFormWidgetState();
}

// Make the state class public so it can be accessed via GlobalKey
class CharacterFormWidgetState extends State<CharacterFormWidget> {
  String? _characterName;
  final Set<String> _selectedAngles = {};

  static const List<String> _studyAngles = [
    'Full life study',
    'Faith journey',
    'Failures & redemption',
    'How they point to Christ',
  ];

  /// Public method to get form data
  Map<String, dynamic> getFormData() {
    return {
      'characterName': _characterName ?? '',
      'studyAngles': _selectedAngles.toList(),
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
      _characterName != null && _characterName!.trim().isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character name field
        Text(
          'Character Name',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'e.g., David, Moses, Peter',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _characterName = value.isEmpty ? null : value;
              _validateForm();
            });
          },
        ),

        const SizedBox(height: 24),

        // Study angle chips
        Text(
          'Study Angle (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select one or more angles to focus the study',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _studyAngles.map((angle) {
            final isSelected = _selectedAngles.contains(angle);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAngles.remove(angle);
                  } else {
                    _selectedAngles.add(angle);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4fc87a).withOpacity(0.12)
                      : (isDark
                          ? const Color(0xFF0f1020)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4fc87a)
                        : (isDark
                            ? const Color(0xFF14162a)
                            : const Color(0xFFeeecff)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  angle,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF4fc87a)
                        : theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4fc87a).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4fc87a).withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFF4fc87a),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The study will explore this character\'s life, faith journey, and theological significance in redemptive history.',
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
