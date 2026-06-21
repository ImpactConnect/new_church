import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/speak_with_models.dart';
import '../screens/speak_with_conversation_screen.dart';
import '../providers/speak_with_providers.dart';

// Pre-loaded figures for the dropdown - used in addition to curated figures from the repository
const _preloadedAuthors = [
  'Moses',
  'Paul',
  'David',
  'Isaiah',
  'Jeremiah',
  'John the Apostle',
  'Luke',
  'James',
  'Peter',
  'Solomon',
  'Ezra',
  'Nehemiah',
];

const _preloadedCharacters = [
  'Ruth',
  'Esther',
  'Mary Magdalene',
  'Elijah',
  'Joshua',
  'Joseph',
  'Rahab',
  'Gideon',
  'Deborah',
  'Samson',
  'Hannah',
  'Daniel',
];

/// Shows a dialog to create a new conversation
void showNewConversationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    builder: (context) => const _NewConversationDialog(),
  );
}

class _NewConversationDialog extends ConsumerStatefulWidget {
  const _NewConversationDialog();

  @override
  ConsumerState<_NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState
    extends ConsumerState<_NewConversationDialog> {
  ConversationMode _selectedMode = ConversationMode.author;
  final _figureAController = TextEditingController();

  @override
  void dispose() {
    _figureAController.dispose();
    super.dispose();
  }

  List<String> get _namesForMode {
    if (_selectedMode == ConversationMode.author) return _preloadedAuthors;
    return _preloadedCharacters;
  }

  String? get _activeNameA => _figureAController.text.trim().isNotEmpty
      ? _figureAController.text.trim()
      : null;

  bool get _canStart {
    if (_activeNameA == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final figuresAsync = ref.watch(curatedFiguresProvider);
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * 0.92),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New Conversation',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SegmentedButton<ConversationMode>(
                  segments: const [
                    ButtonSegment(
                      value: ConversationMode.author,
                      label: Text('Author', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.history_edu, size: 16),
                    ),
                    ButtonSegment(
                      value: ConversationMode.character,
                      label: Text('Character', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.person, size: 16),
                    ),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (Set<ConversationMode> s) {
                    setState(() {
                      _selectedMode = s.first;
                      _figureAController.clear();
                    });
                  },
                ),
                const SizedBox(height: 24),

                figuresAsync.when(
                  data: (figures) {
                    final curatedNames = figures.map((f) => f.name).toList();
                    final combined = {
                      ...curatedNames,
                      ..._namesForMode,
                    }.toList()..sort();
                    return _FigureInputField(
                      key: ValueKey('${_selectedMode.name}A'),
                      controller: _figureAController,
                      label: 'Select or type a name',
                      names: combined,
                      onChanged: (_) => setState(() {}),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, error) => _FigureInputField(
                    key: ValueKey('${_selectedMode.name}A'),
                    controller: _figureAController,
                    label: 'Type a biblical figure name',
                    names: _namesForMode,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select from the list or type any biblical figure\'s name.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _canStart
                      ? () => _startConversation(context, ref)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Conversation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startConversation(BuildContext context, WidgetRef ref) {
    final nameA = _activeNameA!;
    Navigator.pop(context);
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => SpeakWithConversationScreen(
        figureId: nameA.toLowerCase().replaceAll(' ', '_'),
        mode: _selectedMode,
        figureName: nameA,
      ),
    ));
  }
}

/// A combined TextField + Dropdown for figure selection
class _FigureInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<String> names;
  final ValueChanged<String?> onChanged;

  const _FigureInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.names,
    required this.onChanged,
  });

  @override
  State<_FigureInputField> createState() => _FigureInputFieldState();
}

class _FigureInputFieldState extends State<_FigureInputField> {
  List<String> _filtered = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.names;
    widget.controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    final query = widget.controller.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.names
          : widget.names.where((n) => n.toLowerCase().contains(query)).toList();
      _showDropdown = true;
    });
    widget.onChanged(
      widget.controller.text.trim().isEmpty
          ? null
          : widget.controller.text.trim(),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxDropdownHeight =
        mediaQuery.size.height *
        (mediaQuery.viewInsets.bottom > 0 ? 0.18 : 0.24);
    final visibleItems = _filtered.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
          ),
          onTap: () => setState(() => _showDropdown = true),
          onSubmitted: (v) {
            setState(() => _showDropdown = false);
            widget.onChanged(v.trim().isEmpty ? null : v.trim());
          },
        ),
        if (_showDropdown && visibleItems.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxHeight: maxDropdownHeight.clamp(96.0, 180.0),
            ),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final name = visibleItems[index];
                return ListTile(
                  dense: true,
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    widget.controller.text = name;
                    widget.onChanged(name);
                    setState(() => _showDropdown = false);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
