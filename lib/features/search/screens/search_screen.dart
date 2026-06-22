import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bible_ai/features/bible/screens/chapter_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../providers/search_providers.dart';
import '../repositories/search_repository.dart';

/// Enhanced search screen with auto-suggest, story search, and history
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _recentSearches = [];
  bool _showSuggestions = false;
  String? _lastSemanticQuery;
  static const _recentBoxName = 'recent_searches';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _searchController.text.trim();
    setState(() {
      _showSuggestions = text.isNotEmpty && text.length < 3;
    });

    // Cancel existing debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set new debounce timer - wait 500ms before triggering search
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (text.length >= 3) {
        if (ref.read(searchQueryNotifierProvider) != text) {
          setState(() {
            _lastSemanticQuery = null;
          });
          ref.read(searchQueryNotifierProvider.notifier).setQuery(text);
        }
      } else if (text.isEmpty && ref.read(searchQueryNotifierProvider).isNotEmpty) {
        // Clear results if text is cleared
        ref.read(searchQueryNotifierProvider.notifier).setQuery('');
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    final box = await Hive.openBox<String>(_recentBoxName);
    setState(() {
      _recentSearches = box.values.toList().reversed.toList();
    });
  }

  Future<void> _addRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final box = await Hive.openBox<String>(_recentBoxName);

    // Remove duplicate if exists
    final keys = box.keys.toList();
    for (final key in keys) {
      if (box.get(key) == q) {
        await box.delete(key);
      }
    }

    await box.add(q);
    // Keep only last 20
    while (box.length > 20) {
      await box.delete(box.keys.first);
    }
    await _loadRecentSearches();
  }

  Future<void> _clearHistory() async {
    final box = await Hive.openBox<String>(_recentBoxName);
    await box.clear();
    setState(() => _recentSearches = []);
  }

  void _performSearch(String query) {
    _searchController.text = query;
    _focusNode.unfocus();
    setState(() {
      _lastSemanticQuery = null;
    });
    ref.read(searchQueryNotifierProvider.notifier).setQuery(query);
    _addRecentSearch(query);
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryNotifierProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final semanticSearchState = ref.watch(semanticSearchNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search the Scripture')),
      body: Column(
        children: [
          // ── Search Input ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by word, phrase, or story...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(searchQueryNotifierProvider.notifier)
                              .setQuery('');
                          setState(() {
                            _showSuggestions = false;
                            _lastSemanticQuery = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(height: 8),

          // ── Suggestion chips while typing ──
          if (_showSuggestions && _searchController.text.isNotEmpty)
            _buildSuggestionChips(),

          // ── Body ──
          Expanded(
            child: query.isEmpty || query.length < 3
                ? _buildRecentSearches()
                : resultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        // Automatically trigger semantic search if it hasn't been triggered yet for this query
                        if (_lastSemanticQuery != query) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _lastSemanticQuery != query) {
                              setState(() {
                                _lastSemanticQuery = query;
                              });
                              ref
                                  .read(semanticSearchNotifierProvider.notifier)
                                  .performSemanticSearch(query);
                            }
                          });
                        }

                        return semanticSearchState.when(
                          data: (aiResults) {
                            if (aiResults.isEmpty) {
                              return _buildNoResults(query);
                            }
                            return _buildResultsList(
                              aiResults,
                              query,
                              isAiGenerated: true,
                            );
                          },
                          loading: () => _buildDeepSearchLoading(query),
                          error: (err, _) => _buildNoResults(query),
                        );
                      }
                      return _buildResultsList(results, query);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    // Show matching recent searches as quick suggestions
    final text = _searchController.text.toLowerCase();
    final matching = _recentSearches
        .where((s) => s.toLowerCase().contains(text))
        .take(5)
        .toList();

    if (matching.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: matching.map((s) {
          return ActionChip(
            avatar: const Icon(Icons.history, size: 16),
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: () => _performSearch(s),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search the Bible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by word, phrase, or try a story description\nlike "David kills Goliath"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Searches',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ..._recentSearches.map(
          (search) => ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            title: Text(search, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.north_west, size: 14),
            dense: true,
            onTap: () => _performSearch(search),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeepSearchLoading(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Carrying out deep search...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for themes related to "$query"',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different word or phrase',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    List<SearchResult> results,
    String query, {
    bool isAiGenerated = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.length} result${results.length == 1 ? '' : 's'} found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (isAiGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deep Search',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
        final result = results[index - 1];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              '${result.bookName} ${result.chapterNumber}:${result.verseNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isAiGenerated && result.aiReason != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.insights,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          result.aiReason!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              _addRecentSearch(
                query,
              ); // Save to history when a result is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterScreen(
                    bookId: result.bookId,
                    chapterNumber: result.chapterNumber,
                    initialVerseNumber: result.verseNumber,
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }
}
