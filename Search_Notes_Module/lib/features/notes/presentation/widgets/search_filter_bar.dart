import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../providers/standalone_notes_providers.dart';

/// Search and filter bar widget for notes screen
class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  final _searchController = TextEditingController();
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    final notesAsync = ref.read(notesProvider);
    notesAsync.whenData((notes) {
      final allTags = <String>{};
      for (final note in notes) {
        allTags.addAll(note.tags);
      }
      if (mounted) {
        setState(() {
          _availableTags = allTags.toList()..sort();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value.trim();
            },
          ),
        ),

        // Tag filter chips
        if (_availableTags.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableTags.length,
              itemBuilder: (context, index) {
                final tag = _availableTags[index];
                final isSelected = selectedTags.contains(tag);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      final currentTags = List<String>.from(selectedTags);
                      if (selected) {
                        currentTags.add(tag);
                      } else {
                        currentTags.remove(tag);
                      }
                      ref.read(selectedTagsProvider.notifier).state =
                          currentTags;
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
