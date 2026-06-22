import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/ai/ai_models.dart';
import '../../../data/models/ai/chat_session_model.dart';
import '../providers/bible_providers.dart';
import '../services/chat_pdf_service.dart';
import '../providers/chat_session_providers.dart';
import '../widgets/ai_markdown_body.dart';

// Import standalone notes feature
import '../../notes/presentation/widgets/add_to_note_dialog.dart';
import '../../notes/services/content_linker_service.dart';
import '../../notes/data/models/linked_content_reference.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:church_mobile/services/community_auth_service.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final String? bookName;
  final int? chapterNumber;
  final int? verseNumber;
  final String? verseText;
  final String? preloadedContext;
  final String? initialAssistantMessage;
  final String? hiddenAutoPrompt;
  final String? topic;
  final ChatSessionModel? existingSession; // Resume a saved session
  final bool showWelcomeMessageOnNewSession;

  const AiChatScreen({
    super.key,
    this.bookName,
    this.chapterNumber,
    this.verseNumber,
    this.verseText,
    this.preloadedContext,
    this.initialAssistantMessage,
    this.hiddenAutoPrompt,
    this.topic,
    this.existingSession,
    this.showWelcomeMessageOnNewSession = false,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  String _userFirstName = 'there';

  String _getWelcomeMessage() {
    return 'Hi $_userFirstName, so nice to meet you here. I am always available 24/7 to help answer your spiritual concerns, unpack the Scriptures, and walk with you in your faith journey. What is on your heart today?';
  }

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  late ChatSessionModel _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    try {
      final authService = CommunityAuthService();
      final user = await authService.getCurrentUser();
      if (user != null && user.displayName.isNotEmpty) {
        _userFirstName = user.displayName.split(' ').first;
      } else {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null && fbUser.displayName != null && fbUser.displayName!.isNotEmpty) {
          _userFirstName = fbUser.displayName!.split(' ').first;
        }
      }
    } catch (_) {}

    if (widget.existingSession != null) {
      _loadSession(widget.existingSession!);
      return;
    }

    // Try to find an existing session matching this topic or verse
    final repo = ref.read(chatSessionRepositoryProvider.notifier);
    final allSessions = await repo.getAllSessions();
    ChatSessionModel? match;

    if (widget.bookName != null &&
        widget.chapterNumber != null &&
        widget.verseNumber != null) {
      match = allSessions
          .where(
            (s) =>
                s.bookName == widget.bookName &&
                s.chapterNumber == widget.chapterNumber &&
                s.verseNumber == widget.verseNumber,
          )
          .firstOrNull;
    } else if (widget.topic != null) {
      match = allSessions.where((s) => s.title == widget.topic).firstOrNull;
    }

    if (match != null) {
      _loadSession(match);
    } else {
      _createNewSession();
    }
  }

  void _loadSession(ChatSessionModel session) {
    _session = session;
    if (mounted) {
      setState(() {
        for (final m in _session.messages) {
          _messages.add(
            ChatMessage(
              message: m.message,
              isUser: m.isUser,
              isHidden: m.isHidden,
            ),
          );
        }
        _isInitializing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _createNewSession() {
    final sessionId = const Uuid().v4();
    final title =
        widget.topic ??
        (widget.bookName != null
            ? '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}'
            : 'General Chat');

    _session = ChatSessionModel(
      id: sessionId,
      title: title,
      preloadedContext: widget.preloadedContext,
      hiddenAutoPrompt: widget.hiddenAutoPrompt,
      bookName: widget.bookName,
      chapterNumber: widget.chapterNumber,
      verseNumber: widget.verseNumber,
      verseText: widget.verseText,
    );

    if (mounted) {
      setState(() {
        if (widget.showWelcomeMessageOnNewSession) {
          _messages.add(
            ChatMessage(message: _getWelcomeMessage(), isUser: false),
          );
        }
        _isInitializing = false;
      });
    }

    if (widget.showWelcomeMessageOnNewSession) {
      _persistMessages();
    }

    // Trigger hidden auto-prompt or static initial message
    if (widget.hiddenAutoPrompt != null &&
        widget.hiddenAutoPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendHiddenInitialMessage(widget.hiddenAutoPrompt!);
      });
    } else if (widget.preloadedContext != null &&
        widget.preloadedContext!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                message:
                    widget.initialAssistantMessage ??
                    'I have reviewed the context of your evaluation on: **${widget.topic ?? 'this topic'}**.\n\nAsk me any further questions you have regarding this biblical analysis!',
                isUser: false,
              ),
            );
          });
          _persistMessages();
        }
      });
    }
  }

  // ── Persistence helper ───────────────────────────────────────────

  Future<void> _persistMessages() async {
    _session.messages = _messages
        .map(
          (m) => ChatMessageModel(
            message: m.message,
            isUser: m.isUser,
            isHidden: m.isHidden,
            timestamp: DateTime.now(),
          ),
        )
        .toList();
    final repo = ref.read(chatSessionRepositoryProvider.notifier);
    await repo.saveSession(_session);
    // Invalidate the provider so it re-reads
    ref.invalidate(chatSessionsProvider);
  }

  // ── Hidden auto-prompt ───────────────────────────────────────────

  Future<void> _sendHiddenInitialMessage(String text) async {
    setState(() {
      _messages.add(ChatMessage(message: text, isUser: true, isHidden: true));
      _isLoading = true;
      _messages.add(ChatMessage(message: '', isUser: false));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final service = ref.read(aiServiceProvider);
      final version = ref.read(bibleVersionNotifierProvider);

      String currentResponse = '';

      final stream = widget.bookName != null
          ? service.chatWithVerse(
              bookName: widget.bookName!,
              chapterNumber: widget.chapterNumber!,
              verseNumber: widget.verseNumber!,
              verseText: widget.verseText!,
              userMessage: text,
              version: version,
              history: _messages.sublist(0, _messages.length - 2),
              userName: _userFirstName,
            )
          : service.chatGeneral(
              userMessage: text,
              history: _messages.sublist(0, _messages.length - 2),
              preloadedContext: widget.preloadedContext,
              userName: _userFirstName,
            );

      await for (final chunk in stream) {
        currentResponse += chunk;
        if (mounted) {
          setState(() {
            _messages.last = ChatMessage(
              message: currentResponse,
              isUser: false,
            );
          });
          _scrollToBottom();
        }
      }

      // Persist after AI finishes
      await _persistMessages();
    } catch (e) {
      if (mounted) {
        if (_messages.isNotEmpty && _messages.last.message.isEmpty) {
          setState(() {
            _messages.removeLast();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    setState(() {
      _messages.add(ChatMessage(message: text, isUser: true));
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final service = ref.read(aiServiceProvider);
      final version = ref.read(bibleVersionNotifierProvider);

      String currentResponse = '';
      setState(() {
        _messages.add(ChatMessage(message: '', isUser: false));
      });

      final stream = widget.bookName != null
          ? service.chatWithVerse(
              bookName: widget.bookName!,
              chapterNumber: widget.chapterNumber!,
              verseNumber: widget.verseNumber!,
              verseText: widget.verseText!,
              userMessage: text,
              version: version,
              history: _messages.sublist(0, _messages.length - 2),
              userName: _userFirstName,
            )
          : service.chatGeneral(
              userMessage: text,
              history: _messages.sublist(0, _messages.length - 2),
              preloadedContext: widget.preloadedContext,
              userName: _userFirstName,
            );

      await for (final chunk in stream) {
        currentResponse += chunk;
        if (mounted) {
          setState(() {
            _messages.last = ChatMessage(
              message: currentResponse,
              isUser: false,
            );
          });
          _scrollToBottom();
        }
      }

      // Persist after AI finishes responding
      await _persistMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
        if (_messages.isNotEmpty && _messages.last.message.isEmpty) {
          setState(() {
            _messages.removeLast();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _exportChatPdf() async {
    final visibleMessages = _messages.where((m) => !m.isHidden).toList();
    if (visibleMessages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No messages to export.')));
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

      final path = await ChatPdfService.exportChatSession(
        _session,
        visibleMessages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat exported successfully to:\n$path'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ask GSW')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ask GSW', style: TextStyle(fontSize: 16)),
            if (widget.bookName != null)
              Text(
                '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}',
                style: Theme.of(context).textTheme.labelSmall,
              )
            else if (widget.topic != null)
              Text(widget.topic!, style: Theme.of(context).textTheme.labelSmall)
            else
              Text(
                'Your Pastor',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _exportChatPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final visibleMessages = _messages
                    .where((m) => !m.isHidden)
                    .toList();
                if (visibleMessages.isEmpty && !_isLoading) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    final msg = visibleMessages[index];
                    return _buildMessage(msg);
                  },
                );
              },
            ),
          ),
          if (_isLoading && _messages.isNotEmpty && _messages.last.isUser)
            const LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.topic != null
                  ? 'Ask a question about this ${widget.topic}'
                  : 'Ask a question about this verse',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.topic != null
                  ? 'Example: "Explain the historical perspective further" or "Are there other verses about this?"'
                  : 'Example: "What does this mean for me?" or "How does this relate to other verses?"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isUser ? const Radius.circular(0) : null,
              bottomLeft: !isUser ? const Radius.circular(0) : null,
            ),
          ),
          child: isUser
              ? Text(
                  msg.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : AiMarkdownBody(data: msg.message),
        ),
      ),
    );
  }

  void _showMessageActions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              msg.isUser ? 'Your Message' : 'Pastor GSW\'s Response',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Save to Note'),
              onTap: () {
                Navigator.pop(context);
                _saveMessageToNote(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy to clipboard
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMessageToNote(ChatMessage msg) async {
    // Determine the sender
    final sender = msg.isUser ? 'You' : 'Pastor GSW';

    // Format the content using ContentLinkerService
    final formattedContent = ContentLinkerService.formatChatMessage(
      sender: sender,
      timestamp: DateTime.now(),
      message: msg.message,
    );

    // Create reference string
    String reference = 'Chat';
    if (widget.bookName != null) {
      reference =
          'Chat: ${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}';
    } else if (widget.topic != null) {
      reference = 'Chat: ${widget.topic}';
    }

    // Create the linked content reference
    final linkedContentRef = LinkedContentReference(
      id: const Uuid().v4(),
      type: LinkedContentType.chat,
      sourceId: _session.id ?? const Uuid().v4(),
      sourceReference: reference,
      linkedAt: DateTime.now(),
      metadata: {
        'sessionId': _session.id ?? '',
        'sender': sender,
        'timestamp': DateTime.now().toIso8601String(),
        if (widget.bookName != null) 'bookName': widget.bookName!,
        if (widget.chapterNumber != null)
          'chapterNumber': widget.chapterNumber.toString(),
        if (widget.verseNumber != null)
          'verseNumber': widget.verseNumber.toString(),
        if (widget.topic != null) 'topic': widget.topic!,
      },
    );

    // Show the AddToNoteDialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddToNoteDialog(
        formattedContent: formattedContent,
        linkedContentReference: linkedContentRef,
        suggestedTitle: reference,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: IconButton.filled(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
