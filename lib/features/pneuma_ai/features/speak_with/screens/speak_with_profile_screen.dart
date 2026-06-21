import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/speak_with_providers.dart';
import '../models/speak_with_models.dart';

import 'speak_with_conversation_screen.dart';

class SpeakWithProfileScreen extends ConsumerWidget {
  final String figureId;

  const SpeakWithProfileScreen({super.key, required this.figureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(filteredFiguresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Figure Profile'),
        centerTitle: true,
      ),
      body: figuresAsync.when(
        data: (figures) {
          final figure = figures.firstWhere(
            (f) => f.id == figureId,
            orElse: () => throw Exception('Figure not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(figure.avatarEmoji, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),
                Text(
                  figure.displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  figure.era,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Introduction',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        figure.characterIntroduction,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Topics I can speak about',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: figure.topicsTheyCanSpeak.map((t) => Chip(
                    label: Text(t),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  )).toList(),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpeakWithConversationScreen(
                            figureId: figure.id,
                            mode: figure.figureType == FigureType.author 
                                ? ConversationMode.author 
                                : ConversationMode.character,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      'Start Conversation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: \$err')),
      ),
    );
  }
}
