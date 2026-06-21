import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/speak_with_providers.dart';
import '../models/speak_with_models.dart';

class SpeakWithFigureSelectionScreen extends ConsumerWidget {
  const SpeakWithFigureSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(filteredFiguresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Figure'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark 
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
              ),
              onChanged: (val) {
                ref.read(speakWithSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),
          
          Expanded(
            child: figuresAsync.when(
              data: (figures) {
                if (figures.isEmpty) {
                  return const Center(
                    child: Text('No figures found.'),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: figures.length,
                  itemBuilder: (context, index) {
                    final figure = figures[index];
                    return _buildFigureCard(context, figure, isDark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: \$err')),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFigureCard(BuildContext context, BiblicalFigure figure, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/speak_with/profile/\${figure.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark 
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
            : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
               color: Colors.black.withValues(alpha: 0.03),
               blurRadius: 10,
               offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              figure.avatarEmoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              figure.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                figure.role,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                figure.testament == Testament.ot ? 'Old Testament' : 'New Testament',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
