import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../bible/widgets/ai_markdown_body.dart';
import '../../notes/presentation/widgets/add_to_note_dialog.dart';
import '../../notes/data/models/linked_content_reference.dart';
import '../providers/speak_with_providers.dart';
import '../models/speak_with_models.dart';

class SpeakWithConversationScreen extends ConsumerStatefulWidget {
  final String figureId;
  final String? figure2Id;
  final ConversationMode mode;
  final String? figureName;
  final String? figureBName;
  final SpeakWithConversation? existingConversation;

  const SpeakWithConversationScreen({
    super.key,
    required this.figureId,
    this.figure2Id,
    required this.mode,
    this.figureName,
    this.figureBName,
    this.existingConversation,
  });

  @override
  ConsumerState<SpeakWithConversationScreen> createState() =>
      _SpeakWithConversationScreenState();
}

class _SpeakWithConversationScreenState
    extends ConsumerState<SpeakWithConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // ── RESUME existing session ───────────────────────────────────────
    if (widget.existingConversation != null) {
      ref
          .read(askSpeakWithControllerProvider.notifier)
          .resumeConversation(widget.existingConversation!);
      return;
    }

    // ── NEW conversation ─────────────────────────────────────────────
    final figures = await ref.read(curatedFiguresProvider.future);

    BiblicalFigure figureA;
    try {
      figureA = figures.firstWhere(
        (f) =>
            f.id == widget.figureId ||
            f.name.toLowerCase() ==
                (widget.figureName ?? widget.figureId).toLowerCase(),
      );
    } catch (_) {
      figureA = _createCustomFigure(widget.figureName ?? widget.figureId);
    }

    BiblicalFigure? figureB;
    if (widget.mode == ConversationMode.dual && widget.figureBName != null) {
      try {
        figureB = figures.firstWhere(
          (f) => f.name.toLowerCase() == widget.figureBName!.toLowerCase(),
        );
      } catch (_) {
        figureB = _createCustomFigure(widget.figureBName!);
      }
    }

    final greeting = _greeting(figureA, figureB, widget.mode);
    final initialMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      message: greeting,
      isUser: false,
      sentAt: DateTime.now(),
    );

    final conversation = SpeakWithConversation(
      id: DateTime.now().toIso8601String(),
      mode: widget.mode,
      figureA: figureA,
      figureB: figureB,
      messages: [initialMsg],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
    ref
        .read(askSpeakWithControllerProvider.notifier)
        .setConversation(conversation);
  }

  BiblicalFigure _createCustomFigure(String name) {
    return BiblicalFigure(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      displayName: name,
      testament: Testament.nt,
      figureType: FigureType.both,
      era: 'Biblical Era',
      role: 'Biblical Figure',
      avatarEmoji: '📖',
      books: [],
      characterIntroduction: '$name, a biblical figure.',
      topicsTheyCanSpeak: ['Scripture', 'Faith', "God's Calling"],
      topicLimits: [],
      suggestedOpeningQuestions: [
        'Tell me about your life.',
        'What was your greatest trial?',
      ],
      availableSourceTiers: [SourceTier.scripture, SourceTier.historical],
      corpus: FigureCorpus(
        tier1Scripture: 'Scriptures related to $name.',
        personalityProfile: 'A faithful servant of God with deep conviction.',
        knownRelationships: [],
      ),
    );
  }

  String _greeting(BiblicalFigure a, BiblicalFigure? b, ConversationMode mode) {
    if (mode == ConversationMode.dual && b != null) {
      return 'Greetings, friend. We are ${a.name} and ${b.name}. It is a '
          'blessing to gather here with you. We both walked different paths '
          'in service to the Most High, yet we share the same God. What would '
          'you like to ask us today?';
    } else if (mode == ConversationMode.author) {
      return "Peace be with you. I am ${a.name}. The words I penned were "
          "set down in obedience to God's leading — written from the depths of "
          "my experience, my struggles, and my encounters with the living God. "
          "What would you like to ask me about what I wrote, and why?";
    } else {
      return "Shalom, friend. I am ${a.name}. My life was not one of ease — "
          "I have known hardship, grace, and the faithful hand of God in ways "
          "that still move me deeply. What would you like to know about my "
          "journey, my people, or the God I served?";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    await ref.read(askSpeakWithControllerProvider.notifier).sendMessage(text);

    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  // ── Message action handlers ───────────────────────────────────────

  void _copyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareMessage(ChatMessage msg, String figureName) {
    // ignore: deprecated_member_use
    Share.share(
      '$figureName says:\n\n"${msg.message}"\n\n— illuminare Speak With',
      subject: 'Conversation with $figureName',
    );
  }

  void _addMessageToNote(ChatMessage msg, String figureName, String sessionId) {
    final formattedContent =
        '**$figureName:**\n\n${msg.message}\n\n*— Speak With conversation on ${DateTime.now().toLocal().toString().split(' ').first}*';

    final linkedRef = LinkedContentReference(
      id: const Uuid().v4(),
      type: LinkedContentType.chat,
      sourceId: sessionId,
      sourceReference: 'Speak With: $figureName',
      linkedAt: DateTime.now(),
      metadata: {
        'feature': 'Speak With',
        'figure': figureName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    showDialog(
      context: context,
      builder: (context) => AddToNoteDialog(
        formattedContent: formattedContent,
        linkedContentReference: linkedRef,
        suggestedTitle: 'Speak With $figureName',
      ),
    );
  }

  void _showMessageActions(ChatMessage msg, SpeakWithConversation state) {
    final figureName = state.figureA.name;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMessage(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('Add to Note'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addMessageToNote(msg, figureName, state.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareMessage(msg, figureName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askSpeakWithControllerProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = state.mode == ConversationMode.dual && state.figureB != null
        ? '${state.figureA.name} & ${state.figureB!.name}'
        : state.figureA.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              '${state.figureA.era} · ${state.figureA.role}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showFigureInfo(context, state.figureA),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _buildEmptyState(state.figureA)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(state.messages[index], state),
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BiblicalFigure figure) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(figure.avatarEmoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Speak with ${figure.displayName}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              figure.characterIntroduction,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, SpeakWithConversation state) {
    final isUser = msg.isUser;

    if (isUser) {
      // User bubble — right aligned, no menu
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius:
                BorderRadius.circular(16).copyWith(bottomRight: Radius.zero),
          ),
          child: Text(
            msg.message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1.4),
          ),
        ),
      );
    }

    // AI bubble — left aligned, with action menu icon on the right
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message bubble
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(16).copyWith(bottomLeft: Radius.zero),
              ),
              child: AiMarkdownBody(data: msg.message),
            ),
          ),
          // '...' menu button
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.more_horiz,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
              onPressed: () => _showMessageActions(msg, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Speak with them...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void _showFigureInfo(BuildContext context, BiblicalFigure figure) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text(figure.avatarEmoji,
                  style: const TextStyle(fontSize: 48))),
              const SizedBox(height: 12),
              Center(
                child: Text(figure.displayName,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Center(
                child: Text(figure.era,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Introduction',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(figure.characterIntroduction,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5)),
              if (figure.suggestedOpeningQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Suggested Questions',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...figure.suggestedOpeningQuestions.map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 14),
                        label:
                            Flexible(child: Text(q, textAlign: TextAlign.left)),
                        onPressed: () {
                          Navigator.pop(context);
                          _controller.text = q;
                        },
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
