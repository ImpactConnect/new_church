import 'package:flutter/material.dart';
import '../../services/book_service.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    Key? key,
    required this.onCategorySelected,
    required this.onAuthorSelected,
    required this.onTopicsSelected,
    required this.onClearFilters,
    required this.hasActiveFilters,
    this.selectedCategory,
    this.selectedAuthor,
    this.selectedTopics,
  }) : super(key: key);
  final Function(String?) onCategorySelected;
  final Function(String?) onAuthorSelected;
  final Function(List<String>?) onTopicsSelected;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;
  final String? selectedCategory;
  final String? selectedAuthor;
  final List<String>? selectedTopics;

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Theology',
            'Christian Living',
            'Bible Study',
            'Ministry',
            'Biography',
          ].map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                onCategorySelected(category);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showAuthorDialog(BuildContext context) async {
    final BookService bookService = BookService();
    final authors = await bookService.getAuthors();

    if (context.mounted) {
      final selectedAuthor = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Author'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: authors.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(authors[index]),
                    onTap: () {
                      Navigator.of(context).pop(authors[index]);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      onAuthorSelected(selectedAuthor);
    }
  }

  Future<void> _showTopicsDialog(BuildContext context) async {
    final BookService bookService = BookService();
    final topics = await bookService.getTopics();
    final selectedTopicsLocal = <String>{};
    if (selectedTopics != null) {
      selectedTopicsLocal.addAll(selectedTopics!);
    }

    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Topics'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return CheckboxListTile(
                        title: Text(topic),
                        value: selectedTopicsLocal.contains(topic),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedTopicsLocal.add(topic);
                            } else {
                              selectedTopicsLocal.remove(topic);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed == true) {
        onTopicsSelected(selectedTopicsLocal.isEmpty ? null : selectedTopicsLocal.toList());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterRow(
          context,
          icon: Icons.category,
          title: 'Category',
          value: selectedCategory ?? 'All Categories',
          onTap: () => _showCategoryDialog(context),
        ),
        const Divider(height: 1),
        _buildFilterRow(
          context,
          icon: Icons.person,
          title: 'Author',
          value: selectedAuthor ?? 'All Authors',
          onTap: () => _showAuthorDialog(context),
        ),
        const Divider(height: 1),
        _buildFilterRow(
          context,
          icon: Icons.tag,
          title: 'Topics',
          value: selectedTopics?.isNotEmpty == true
              ? '${selectedTopics!.length} Selected'
              : 'All Topics',
          onTap: () => _showTopicsDialog(context),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              onClearFilters();
              Navigator.pop(context); // Optional: close bottom sheet on clear
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Filters'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, {required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
