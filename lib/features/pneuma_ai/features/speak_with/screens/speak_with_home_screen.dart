import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import '../models/speak_with_models.dart';
import 'speak_with_conversation_screen.dart';
import '../providers/speak_with_providers.dart';
import '../widgets/new_conversation_sheet.dart';

class SpeakWithHomeScreen extends ConsumerStatefulWidget {
  const SpeakWithHomeScreen({super.key});

  @override
  ConsumerState<SpeakWithHomeScreen> createState() =>
      _SpeakWithHomeScreenState();
}

class _SpeakWithHomeScreenState extends ConsumerState<SpeakWithHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh saved sessions every time this screen is shown so newly
    // created/updated conversations are reflected immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(savedConversationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentAsync = ref.watch(savedConversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ScriptTalk'), centerTitle: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surfaceContainerLowest],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context, colorScheme),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Recent Conversations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: recentAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return _buildEmptyState(context, colorScheme);
                        }
                        final sorted = [...sessions]
                          ..sort(
                            (a, b) =>
                                b.lastMessageAt.compareTo(a.lastMessageAt),
                          );
                        return Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              return _buildSessionCard(
                                context,
                                sorted[index],
                                colorScheme,
                                ref,
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildEmptyState(context, colorScheme),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewConversationDialog(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New Conversation'),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF673AB7).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ScriptTalk',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Engage in powerful, theology-backed conversations with Biblical figures and authors.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                          colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "New Conversation" to begin engaging.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    SpeakWithConversation session,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            session.figureA.avatarEmoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
        title: Text(
          session.mode == ConversationMode.dual && session.figureB != null
              ? '${session.figureA.name} & ${session.figureB!.name}'
              : session.figureA.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(session.lastMessageAt),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () async {
            await ref
                .read(speakWithRepositoryProvider)
                .deleteConversation(session.id);
            ref.invalidate(savedConversationsProvider);
          },
        ),
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (_) => SpeakWithConversationScreen(
              figureId: session.figureA.id,
              mode: session.mode,
              figureName: session.figureA.name,
              figureBName: session.figureB?.name,
              existingConversation: session,
            ),
          ));
        },
      ),
    );
  }
}
