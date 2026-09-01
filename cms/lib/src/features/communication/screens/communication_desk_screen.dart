import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/features/communication/models/message_model.dart';
import 'package:cms/src/features/communication/models/communication_settings_model.dart';
import 'package:cms/src/features/communication/models/formal_email_model.dart';
import 'package:cms/src/features/communication/services/messaging_service.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _messagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>(
  (ref, branchId) => ref.watch(communicationRepositoryProvider).watchMessages(branchId),
);

final _commSettingsProvider = FutureProvider.autoDispose<CommunicationSettingsModel>(
  (ref) => ref.watch(communicationRepositoryProvider).getCommunicationSettings(),
);

final _formalEmailsProvider = StreamProvider.autoDispose.family<List<FormalEmailModel>, (String, EmailFolder)>(
  (ref, params) => ref.watch(communicationRepositoryProvider).watchFormalEmails(params.$1, params.$2),
);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class CommunicationDeskScreen extends ConsumerStatefulWidget {
  const CommunicationDeskScreen({super.key});

  @override
  ConsumerState<CommunicationDeskScreen> createState() => _CommunicationDeskScreenState();
}

class _CommunicationDeskScreenState extends ConsumerState<CommunicationDeskScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Omnichannel Compose form state
  MessageChannel _channel = MessageChannel.sms;
  RecipientSegment _segment = RecipientSegment.all;
  String? _segmentFilter;
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  int _resolvedCount = 0;
  bool _resolving = false;
  bool _sending = false;
  Timer? _resolveTimer;

  // Omnichannel History state
  MessageModel? _selectedMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCount());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _resolveTimer?.cancel();
    super.dispose();
  }

  String get _branchId => ref.read(currentBranchIdProvider);

  void _refreshCount() {
    _resolveTimer?.cancel();
    _resolveTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _resolving = true);
      try {
        final svc = ref.read(messagingServiceProvider);
        final contacts = await svc.resolveRecipients(
          branchId: _branchId,
          segment: _segment.name,
          filter: _segmentFilter,
        );
        if (mounted) setState(() => _resolvedCount = contacts.length);
      } catch (_) {
        if (mounted) setState(() => _resolvedCount = 0);
      } finally {
        if (mounted) setState(() => _resolving = false);
      }
    });
  }

  Future<void> _send() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      _showSnack('Please write a message before sending.', isError: true);
      return;
    }
    if (_channel == MessageChannel.email && _subjectCtrl.text.trim().isEmpty) {
      _showSnack('Please enter an email subject.', isError: true);
      return;
    }
    if (_channel == MessageChannel.push && _subjectCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a notification title.', isError: true);
      return;
    }

    setState(() => _sending = true);

    final user = ref.read(cmsUserProvider).valueOrNull!;
    final commRepo = ref.read(communicationRepositoryProvider);
    final svc = ref.read(messagingServiceProvider);
    final settings = await commRepo.getCommunicationSettings();

    // Create draft record
    var msg = MessageModel(
      id: '',
      branchId: _branchId,
      channel: _channel,
      subject: _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : null,
      body: body,
      recipientSegment: _segment,
      recipientFilter: _segmentFilter,
      recipientCount: _resolvedCount,
      status: MessageStatus.sending,
      createdBy: user.uid,
      createdByName: user.displayName ?? user.email,
      createdAt: DateTime.now(),
    );

    // Save draft first so it appears in history immediately
    await commRepo.saveMessage(_branchId, msg);

    // Resolve actual contacts
    final contacts = await svc.resolveRecipients(
      branchId: _branchId,
      segment: _segment.name,
      filter: _segmentFilter,
    );

    SendResult result;

    switch (_channel) {
      case MessageChannel.sms:
        final phones = contacts.map((c) => c.phone ?? '').where((p) => p.isNotEmpty).toList();
        result = await svc.sendSms(phones: phones, message: body, settings: settings);
        break;
      case MessageChannel.whatsapp:
        final phones = contacts.map((c) => c.phone ?? '').where((p) => p.isNotEmpty).toList();
        result = await svc.sendWhatsApp(
          phones: phones,
          templateId: settings.whatsappTemplateId,
          message: body,
          settings: settings,
        );
        break;
      case MessageChannel.push:
        final tokens = contacts.map((c) => c.fcmToken ?? '').where((t) => t.isNotEmpty).toList();
        result = await svc.sendPush(
          fcmTokens: tokens,
          title: _subjectCtrl.text.trim(),
          body: body,
          settings: settings,
          data: {'type': 'broadcast'},
        );
        break;
      case MessageChannel.email:
        final emails = contacts.map((c) => c.email ?? '').where((e) => e.isNotEmpty).toList();
        result = await svc.sendEmail(
          addresses: emails,
          subject: _subjectCtrl.text.trim(),
          htmlBody: '<p>${body.replaceAll('\n', '<br>')}</p>',
          settings: settings,
        );
        break;
    }

    // Determine final status
    final finalStatus = result.errorMessage != null
        ? MessageStatus.failed
        : result.failed == 0
            ? MessageStatus.sent
            : result.sent == 0
                ? MessageStatus.failed
                : MessageStatus.partial;

    if (result.errorMessage != null) {
      if (mounted) {
        setState(() => _sending = false);
        _showSnack('⚠ ${result.errorMessage}', isError: true);
      }
      return;
    }

    if (mounted) {
      setState(() => _sending = false);
      final statusMsg = finalStatus == MessageStatus.sent
          ? '✓ Sent to ${result.sent} recipients.'
          : finalStatus == MessageStatus.partial
              ? '⚠ Sent: ${result.sent}, Failed: ${result.failed}'
              : '✗ All ${result.failed} sends failed.';
      _showSnack(statusMsg, isError: finalStatus == MessageStatus.failed);

      if (finalStatus != MessageStatus.failed) {
        _bodyCtrl.clear();
        _subjectCtrl.clear();
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
      backgroundColor: isError ? CmsTheme.danger : CmsTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(cmsUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final canSend = user.can(AppPermission.sendCommunication);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Main Tabs
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CmsPageHeader(
                  title: 'Communication Desk',
                  subtitle: 'Unified church communications & formal external correspondence',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CmsTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: CmsTheme.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: CmsTheme.textSecondary,
                  labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.hub_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Omnichannel Broadcast'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.mark_as_unread_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Formal & External Email'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Omnichannel Broadcast (Members)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Compose panel
                    SizedBox(
                      width: 380,
                      child: _ComposePanel(
                        channel: _channel,
                        segment: _segment,
                        segmentFilter: _segmentFilter,
                        subjectCtrl: _subjectCtrl,
                        bodyCtrl: _bodyCtrl,
                        resolvedCount: _resolvedCount,
                        resolving: _resolving,
                        sending: _sending,
                        canSend: canSend,
                        onChannelChanged: (c) => setState(() => _channel = c),
                        onSegmentChanged: (s) {
                          setState(() {
                            _segment = s;
                            _segmentFilter = null;
                          });
                          _refreshCount();
                        },
                        onFilterChanged: (f) {
                          setState(() => _segmentFilter = f);
                          _refreshCount();
                        },
                        onSend: _send,
                        branchId: _branchId,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right: History panel
                    Expanded(
                      child: _HistoryPanel(
                        branchId: _branchId,
                        selectedMessage: _selectedMessage,
                        onMessageSelected: (m) => setState(() => _selectedMessage = m),
                      ),
                    ),
                  ],
                ),

                // Tab 2: Formal Email Desk (Non-members, Banks, Contractors, CC, Attachments, Inbox/Sent/Drafts Modal Dialog)
                _FormalEmailTab(branchId: _branchId, canSend: canSend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 2: Formal Email Desk (2-Column layout, click item opens dialog with reply options) ─────

class _FormalEmailTab extends ConsumerStatefulWidget {
  const _FormalEmailTab({required this.branchId, required this.canSend});

  final String branchId;
  final bool canSend;

  @override
  ConsumerState<_FormalEmailTab> createState() => _FormalEmailTabState();
}

class _FormalEmailTabState extends ConsumerState<_FormalEmailTab> {
  EmailFolder _folder = EmailFolder.inbox;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openComposeDialog({
    FormalEmailModel? draft,
    String? initialTo,
    String? initialCc,
    String? initialSubject,
    String? initialBody,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormalEmailComposeDialog(
        branchId: widget.branchId,
        draft: draft,
        initialTo: initialTo,
        initialCc: initialCc,
        initialSubject: initialSubject,
        initialBody: initialBody,
      ),
    );
  }

  void _openEmailDetailDialog(FormalEmailModel email) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _FormalEmailDetailDialog(
        email: email,
        branchId: widget.branchId,
        onEditDraft: () {
          Navigator.pop(dialogCtx);
          _openComposeDialog(draft: email);
        },
        onReply: (to, cc, subject, body) {
          Navigator.pop(dialogCtx);
          _openComposeDialog(
            initialTo: to,
            initialCc: cc,
            initialSubject: subject,
            initialBody: body,
          );
        },
        onDelete: () async {
          Navigator.pop(dialogCtx);
          await ref
              .read(communicationRepositoryProvider)
              .deleteFormalEmail(widget.branchId, email.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Email deleted.'), backgroundColor: CmsTheme.info),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(_formalEmailsProvider((widget.branchId, _folder)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Folder Navigation + Compose Button (Width 240)
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: CmsTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CmsTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compose Button
              SizedBox(
                width: double.infinity,
                child: CmsButton(
                  label: 'Compose Email',
                  icon: Icons.edit_note_outlined,
                  onPressed: widget.canSend ? () => _openComposeDialog() : null,
                ),
              ),
              const SizedBox(height: 20),

              // Folder list
              _FolderItem(
                icon: Icons.inbox_outlined,
                label: 'Inbox',
                folder: EmailFolder.inbox,
                selected: _folder,
                onSelect: (f) => setState(() => _folder = f),
              ),
              _FolderItem(
                icon: Icons.send_outlined,
                label: 'Sent Messages',
                folder: EmailFolder.sent,
                selected: _folder,
                onSelect: (f) => setState(() => _folder = f),
              ),
              _FolderItem(
                icon: Icons.drafts_outlined,
                label: 'Drafts',
                folder: EmailFolder.draft,
                selected: _folder,
                onSelect: (f) => setState(() => _folder = f),
              ),
              const Spacer(),

              // Guidance Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: CmsTheme.accent),
                        SizedBox(width: 6),
                        Text(
                          'External Correspondence',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CmsTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Click any email to open in a dialog reader with Reply, Reply All & thread tracking.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Expanded Main Column: Mail List (Fills remaining screen width)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: CmsTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CmsTheme.border),
            ),
            child: Column(
              children: [
                // Header + Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(_folderIcon(_folder), size: 18, color: CmsTheme.accent),
                          const SizedBox(width: 8),
                          Text(
                            _folderName(_folder),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CmsTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          emailsAsync.whenOrNull(
                                data: (list) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CmsTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: CmsTheme.border),
                                  ),
                                  child: Text(
                                    '${list.length} email${list.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: CmsTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ) ??
                              const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (q) => setState(() => _searchQuery = q.toLowerCase().trim()),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search subject, email address, or body content…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: CmsTheme.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: CmsTheme.border),

                // Table List Headers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: CmsTheme.surfaceElevated.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      _ListHeader(_folder == EmailFolder.inbox ? 'From' : 'To', flex: 3),
                      const _ListHeader('Subject & Preview', flex: 6),
                      const _ListHeader('Attachments', flex: 2),
                      const _ListHeader('Date', flex: 2),
                    ],
                  ),
                ),

                // Emails list
                Expanded(
                  child: emailsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: CmsTheme.accent)),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                    data: (emails) {
                      final filtered = emails.where((e) {
                        if (_searchQuery.isEmpty) return true;
                        return e.subject.toLowerCase().contains(_searchQuery) ||
                            e.fromAddress.toLowerCase().contains(_searchQuery) ||
                            e.toAddresses.any((t) => t.toLowerCase().contains(_searchQuery)) ||
                            e.body.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email_outlined, size: 48, color: CmsTheme.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No emails found in ${_folderName(_folder)}',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: CmsTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'New formal correspondence will appear here.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: CmsTheme.border),
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          return _FormalEmailFullRow(
                            email: item,
                            folder: _folder,
                            onTap: () => _openEmailDetailDialog(item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _folderIcon(EmailFolder f) => switch (f) {
        EmailFolder.inbox => Icons.inbox_outlined,
        EmailFolder.sent => Icons.send_outlined,
        EmailFolder.draft => Icons.drafts_outlined,
      };

  String _folderName(EmailFolder f) => switch (f) {
        EmailFolder.inbox => 'Inbox',
        EmailFolder.sent => 'Sent Messages',
        EmailFolder.draft => 'Drafts',
      };
}

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.label, {this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CmsTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FormalEmailFullRow extends StatelessWidget {
  const _FormalEmailFullRow({
    required this.email,
    required this.folder,
    required this.onTap,
  });

  final FormalEmailModel email;
  final EmailFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final senderName = folder == EmailFolder.inbox
        ? (email.fromName.isNotEmpty ? email.fromName : email.fromAddress)
        : 'To: ${email.toAddresses.join(', ')}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Sender / To
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CmsTheme.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (senderName.isNotEmpty ? senderName[0] : 'E').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CmsTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: !email.isRead && folder == EmailFolder.inbox
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: CmsTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (folder == EmailFolder.inbox && email.fromAddress != senderName)
                          Text(
                            email.fromAddress,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subject & Preview
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.subject,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: !email.isRead && folder == EmailFolder.inbox
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: CmsTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.body,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Attachments
            Expanded(
              flex: 2,
              child: email.attachments.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CmsTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 13, color: CmsTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${email.attachments.length} file${email.attachments.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: CmsTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('dd MMM, HH:mm').format(email.createdAt),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FORMAL EMAIL DETAIL DIALOG (Opened on click with Reply & Threading) ────────

class _FormalEmailDetailDialog extends ConsumerWidget {
  const _FormalEmailDetailDialog({
    required this.email,
    required this.branchId,
    required this.onEditDraft,
    required this.onReply,
    required this.onDelete,
  });

  final FormalEmailModel email;
  final String branchId;
  final VoidCallback onEditDraft;
  final Function(String to, String cc, String subject, String body) onReply;
  final VoidCallback onDelete;

  String _cleanSubject(String subj) {
    return subj.replaceAll(RegExp(r'^(Re:\s*|Fwd:\s*)+', caseSensitive: false), '').trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(cmsUserProvider).valueOrNull;

    // Build quote for Reply
    final replyTo = email.folder == EmailFolder.inbox ? email.fromAddress : email.toAddresses.join(', ');
    final replyCc = email.ccAddresses.join(', ');
    final cleanSubj = _cleanSubject(email.subject);
    final replySubj = 'Re: $cleanSubj';
    final quoteHeader = '\n\n\n-----------------------------------------\nOn ${DateFormat('dd MMM yyyy, HH:mm').format(email.createdAt)}, ${email.fromName} <${email.fromAddress}> wrote:\n';
    final quotedBody = email.body.split('\n').map((line) => '> $line').join('\n');
    final replyBody = '$quoteHeader$quotedBody';

    // Reply All recipients
    final replyAllToList = [
      if (email.folder == EmailFolder.inbox) email.fromAddress,
      ...email.toAddresses.where((a) => a != user?.email),
    ].toSet().join(', ');

    return Dialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header & Action Bar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      email.subject,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CmsTheme.textPrimary,
                      ),
                    ),
                  ),

                  // Draft Edit Action
                  if (email.folder == EmailFolder.draft)
                    CmsButton(
                      label: 'Edit Draft',
                      icon: Icons.edit_outlined,
                      compact: true,
                      onPressed: onEditDraft,
                    ),

                  // Reply & Reply All Actions (Inbox & Sent)
                  if (email.folder == EmailFolder.inbox || email.folder == EmailFolder.sent) ...[
                    OutlinedButton.icon(
                      onPressed: () => onReply(replyTo, '', replySubj, replyBody),
                      icon: const Icon(Icons.reply_outlined, size: 16),
                      label: const Text('Reply'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => onReply(replyAllToList, replyCc, replySubj, replyBody),
                      icon: const Icon(Icons.reply_all_outlined, size: 16),
                      label: const Text('Reply All'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Delete & Close
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: CmsTheme.danger, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete Email',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CmsTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20, color: CmsTheme.border),

              // Metadata Cards (From, To, CC, Date)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: Column(
                  children: [
                    _MetaLine('From', '${email.fromName} <${email.fromAddress}>'),
                    const SizedBox(height: 4),
                    _MetaLine('To', email.toAddresses.join(', ')),
                    if (email.ccAddresses.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaLine('CC', email.ccAddresses.join(', ')),
                    ],
                    const SizedBox(height: 4),
                    _MetaLine('Date', DateFormat('EEEE, dd MMMM yyyy • HH:mm').format(email.createdAt)),
                  ],
                ),
              ),

              // Attachments
              if (email.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CmsTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 15, color: CmsTheme.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${email.attachments.length} Attachment${email.attachments.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CmsTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: email.attachments.map((att) {
                          final sizeKb = (att.size / 1024).toStringAsFixed(1);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: CmsTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: CmsTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 15, color: CmsTheme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  att.name,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '($sizeKb KB)',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Email Body Text
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CmsTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CmsTheme.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      email.body,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: CmsTheme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _MetaLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textMuted),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _FolderItem extends StatelessWidget {
  const _FolderItem({
    required this.icon,
    required this.label,
    required this.folder,
    required this.selected,
    required this.onSelect,
  });

  final IconData icon;
  final String label;
  final EmailFolder folder;
  final EmailFolder selected;
  final ValueChanged<EmailFolder> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == folder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelect(folder),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? CmsTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? CmsTheme.accent : CmsTheme.textSecondary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? CmsTheme.accent : CmsTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── COMPOSE FORMAL EMAIL DIALOG (Non-members, CC, Attachments) ───────────────

class _FormalEmailComposeDialog extends ConsumerStatefulWidget {
  const _FormalEmailComposeDialog({
    required this.branchId,
    this.draft,
    this.initialTo,
    this.initialCc,
    this.initialSubject,
    this.initialBody,
  });

  final String branchId;
  final FormalEmailModel? draft;
  final String? initialTo;
  final String? initialCc;
  final String? initialSubject;
  final String? initialBody;

  @override
  ConsumerState<_FormalEmailComposeDialog> createState() => _FormalEmailComposeDialogState();
}

class _FormalEmailComposeDialogState extends ConsumerState<_FormalEmailComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toCtrl;
  late final TextEditingController _ccCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _bodyCtrl;

  final List<AttachmentItem> _attachments = [];
  bool _sending = false;
  bool _savingDraft = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _toCtrl = TextEditingController(text: d?.toAddresses.join(', ') ?? widget.initialTo ?? '');
    _ccCtrl = TextEditingController(text: d?.ccAddresses.join(', ') ?? widget.initialCc ?? '');
    _subjectCtrl = TextEditingController(text: d?.subject ?? widget.initialSubject ?? '');
    _bodyCtrl = TextEditingController(text: d?.body ?? widget.initialBody ?? '');
    if (d != null && d.attachments.isNotEmpty) {
      _attachments.addAll(d.attachments);
    }
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final base64Str = bytes != null ? base64Encode(bytes) : null;

        setState(() {
          _attachments.add(AttachmentItem(
            name: file.name,
            size: file.size,
            base64Content: base64Str,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File pick error: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    }
  }

  List<String> _parseEmails(String text) {
    return text
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();
  }

  Future<void> _saveAsDraft() async {
    setState(() => _savingDraft = true);
    try {
      final user = ref.read(cmsUserProvider).valueOrNull!;
      final model = FormalEmailModel(
        id: widget.draft?.id ?? '',
        branchId: widget.branchId,
        folder: EmailFolder.draft,
        fromAddress: user.email,
        fromName: user.displayName ?? 'Church Secretariat',
        toAddresses: _parseEmails(_toCtrl.text),
        ccAddresses: _parseEmails(_ccCtrl.text),
        subject: _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : '(No Subject)',
        body: _bodyCtrl.text.trim(),
        attachments: _attachments,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        createdByName: user.displayName ?? user.email,
      );

      await ref.read(communicationRepositoryProvider).saveFormalEmail(widget.branchId, model);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Saved as Draft.'), backgroundColor: CmsTheme.info),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _sendFormalEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final toList = _parseEmails(_toCtrl.text);
    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one valid recipient email in "To".'), backgroundColor: CmsTheme.danger),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final user = ref.read(cmsUserProvider).valueOrNull!;
      final commRepo = ref.read(communicationRepositoryProvider);
      final svc = ref.read(messagingServiceProvider);
      final settings = await commRepo.getCommunicationSettings();

      final ccList = _parseEmails(_ccCtrl.text);

      // Convert attachments to Resend API payload format [{ filename, content }]
      final resendAttachments = _attachments
          .where((a) => a.base64Content != null)
          .map((a) => {'filename': a.name, 'content': a.base64Content})
          .toList();

      final result = await svc.sendFormalEmail(
        to: toList,
        cc: ccList,
        subject: _subjectCtrl.text.trim(),
        htmlBody: '<p>${_bodyCtrl.text.trim().replaceAll('\n', '<br>')}</p>',
        attachments: resendAttachments,
        settings: settings,
      );

      if (result.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠ ${result.errorMessage}'), backgroundColor: CmsTheme.danger),
          );
        }
        return;
      }

      // Record in Sent folder
      final sentRecord = FormalEmailModel(
        id: widget.draft?.id ?? '',
        branchId: widget.branchId,
        folder: EmailFolder.sent,
        fromAddress: settings.resendFromEmail.isNotEmpty ? settings.resendFromEmail : user.email,
        fromName: settings.resendFromName.isNotEmpty ? settings.resendFromName : (user.displayName ?? 'Church Secretariat'),
        toAddresses: toList,
        ccAddresses: ccList,
        subject: _subjectCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        attachments: _attachments,
        createdAt: DateTime.now(),
        sentAt: DateTime.now(),
        createdBy: user.uid,
        createdByName: user.displayName ?? user.email,
      );

      await commRepo.saveFormalEmail(widget.branchId, sentRecord);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Formal email sent successfully!'), backgroundColor: CmsTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Title Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CmsTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.mail_outline, color: CmsTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compose Formal Email',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CmsTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Send official correspondence to non-members, partners, or contractors',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: CmsTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24, color: CmsTheme.border),

                // Inputs Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // To (Non-church members, banks, contractors)
                        _InputLabel('To (Recipient Emails — comma separated)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _toCtrl,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter at least one email address' : null,
                          decoration: const InputDecoration(
                            hintText: 'e.g. bank@firstbank.com, contractor@build.ng',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CC (Carbon Copy)
                        _InputLabel('CC (Carbon Copy Emails — optional)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ccCtrl,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'e.g. leadpastor@church.org, secretary@church.org',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subject
                        _InputLabel('Subject'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _subjectCtrl,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject required' : null,
                          decoration: const InputDecoration(
                            hintText: 'Formal subject line…',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Attachments Button + Selected List
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickAttachment,
                              icon: const Icon(Icons.attach_file, size: 16),
                              label: const Text('Attach File (PDF, DOC, Images)'),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_attachments.length} attached',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                            ),
                          ],
                        ),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _attachments.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final att = entry.value;
                              final sizeKb = (att.size / 1024).toStringAsFixed(1);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: CmsTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: CmsTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.insert_drive_file, size: 14, color: CmsTheme.accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${att.name} ($sizeKb KB)',
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textPrimary),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(() => _attachments.removeAt(idx)),
                                      child: const Icon(Icons.close, size: 14, color: CmsTheme.danger),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Body
                        _InputLabel('Email Body'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _bodyCtrl,
                          maxLines: 8,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Body text required' : null,
                          decoration: const InputDecoration(
                            hintText: 'Type your formal message content here…',
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24, color: CmsTheme.border),

                // Dialog Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _savingDraft ? null : _saveAsDraft,
                      icon: const Icon(Icons.drafts_outlined, size: 16),
                      label: const Text('Save Draft'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    CmsButton(
                      label: 'Send Formal Email',
                      icon: Icons.send_outlined,
                      loading: _sending,
                      onPressed: _sendFormalEmail,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _InputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CmsTheme.textSecondary,
      ),
    );
  }
}

// ─── Compose Panel (Omnichannel) ─────────────────────────────────────────────

class _ComposePanel extends ConsumerStatefulWidget {
  const _ComposePanel({
    required this.channel,
    required this.segment,
    required this.segmentFilter,
    required this.subjectCtrl,
    required this.bodyCtrl,
    required this.resolvedCount,
    required this.resolving,
    required this.sending,
    required this.canSend,
    required this.onChannelChanged,
    required this.onSegmentChanged,
    required this.onFilterChanged,
    required this.onSend,
    required this.branchId,
  });

  final MessageChannel channel;
  final RecipientSegment segment;
  final String? segmentFilter;
  final TextEditingController subjectCtrl;
  final TextEditingController bodyCtrl;
  final int resolvedCount;
  final bool resolving;
  final bool sending;
  final bool canSend;
  final ValueChanged<MessageChannel> onChannelChanged;
  final ValueChanged<RecipientSegment> onSegmentChanged;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onSend;
  final String branchId;

  @override
  ConsumerState<_ComposePanel> createState() => _ComposePanelState();
}

class _ComposePanelState extends ConsumerState<_ComposePanel> {
  int get _charCount => widget.bodyCtrl.text.length;

  @override
  void initState() {
    super.initState();
    widget.bodyCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CmsTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CmsTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, color: CmsTheme.accent, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'New Broadcast Message',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel selector
                  _Label('Send Via'),
                  const SizedBox(height: 8),
                  _ChannelSelector(
                    selected: widget.channel,
                    onChanged: widget.onChannelChanged,
                  ),
                  const SizedBox(height: 20),

                  // Recipients
                  _Label('Recipients'),
                  const SizedBox(height: 8),
                  _SegmentDropdown(
                    value: widget.segment,
                    onChanged: widget.onSegmentChanged,
                  ),
                  if (widget.segment != RecipientSegment.all) ...[
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      segment: widget.segment,
                      value: widget.segmentFilter,
                      onChanged: widget.onFilterChanged,
                      branchId: widget.branchId,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Recipient count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: CmsTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CmsTheme.border),
                    ),
                    child: Row(
                      children: [
                        widget.resolving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CmsTheme.accent,
                                ),
                              )
                            : Icon(Icons.people_outline,
                                size: 14,
                                color: widget.resolvedCount > 0
                                    ? CmsTheme.success
                                    : CmsTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          widget.resolving
                              ? 'Counting recipients…'
                              : '${widget.resolvedCount} member${widget.resolvedCount == 1 ? '' : 's'} matched',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.resolvedCount > 0
                                ? CmsTheme.success
                                : CmsTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subject (email and push only)
                  if (widget.channel == MessageChannel.email ||
                      widget.channel == MessageChannel.push) ...[
                    _Label(widget.channel == MessageChannel.email
                        ? 'Subject'
                        : 'Notification Title'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.subjectCtrl,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: CmsTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.channel == MessageChannel.email
                            ? 'Email subject line…'
                            : 'Notification title…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Message body
                  _Label(_bodyLabel(widget.channel)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: widget.bodyCtrl,
                    maxLines: 8,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: _bodyHint(widget.channel),
                      contentPadding: const EdgeInsets.all(14),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Character counter + SMS info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.channel == MessageChannel.sms ||
                          widget.channel == MessageChannel.whatsapp)
                        Text(
                          _charCount > 160
                              ? '${(_charCount / 160).ceil()} SMS pages'
                              : '${160 - _charCount} chars remaining',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: _charCount > 160
                                ? CmsTheme.warning
                                : CmsTheme.textMuted,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '$_charCount chars',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: CmsTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Config warning if gateway not configured
                  _ConfigWarning(channel: widget.channel),
                  const SizedBox(height: 12),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: widget.canSend
                        ? CmsButton(
                            label: 'Send ${_channelLabel(widget.channel)}',
                            loading: widget.sending,
                            onPressed: widget.onSend,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: CmsTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CmsTheme.border),
                            ),
                            child: const Text(
                              'No permission to send messages',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textMuted),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bodyLabel(MessageChannel ch) => switch (ch) {
        MessageChannel.email => 'Email Body',
        MessageChannel.push => 'Notification Body',
        MessageChannel.sms => 'SMS Message',
        MessageChannel.whatsapp => 'WhatsApp Message',
      };

  String _bodyHint(MessageChannel ch) => switch (ch) {
        MessageChannel.email => 'Type your email content here…',
        MessageChannel.push => 'Short notification body (keep concise)…',
        MessageChannel.sms => 'Keep under 160 characters for single SMS…',
        MessageChannel.whatsapp => 'Type your WhatsApp message…',
      };

  String _channelLabel(MessageChannel ch) => switch (ch) {
        MessageChannel.sms => 'SMS',
        MessageChannel.push => 'Push Notification',
        MessageChannel.email => 'Email',
        MessageChannel.whatsapp => 'WhatsApp',
      };
}

// ─── Channel Selector ─────────────────────────────────────────────────────────

class _ChannelSelector extends StatelessWidget {
  const _ChannelSelector({required this.selected, required this.onChanged});

  final MessageChannel selected;
  final ValueChanged<MessageChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MessageChannel.values.map((ch) {
        final isSelected = selected == ch;
        return GestureDetector(
          onTap: () => onChanged(ch),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _channelColor(ch).withValues(alpha: 0.15)
                  : CmsTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _channelColor(ch) : CmsTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_channelIcon(ch), size: 16, color: isSelected ? _channelColor(ch) : CmsTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _channelName(ch),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? _channelColor(ch) : CmsTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _channelIcon(MessageChannel ch) => switch (ch) {
        MessageChannel.sms => Icons.sms_outlined,
        MessageChannel.push => Icons.notifications_outlined,
        MessageChannel.email => Icons.email_outlined,
        MessageChannel.whatsapp => Icons.chat_bubble_outline,
      };

  String _channelName(MessageChannel ch) => switch (ch) {
        MessageChannel.sms => 'SMS',
        MessageChannel.push => 'Push',
        MessageChannel.email => 'Email',
        MessageChannel.whatsapp => 'WhatsApp',
      };

  Color _channelColor(MessageChannel ch) => switch (ch) {
        MessageChannel.sms => CmsTheme.info,
        MessageChannel.push => CmsTheme.accent,
        MessageChannel.email => CmsTheme.warning,
        MessageChannel.whatsapp => const Color(0xFF25D366),
      };
}

// ─── Segment Dropdown ─────────────────────────────────────────────────────────

class _SegmentDropdown extends StatelessWidget {
  const _SegmentDropdown({required this.value, required this.onChanged});

  final RecipientSegment value;
  final ValueChanged<RecipientSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RecipientSegment>(
      value: value,
      dropdownColor: CmsTheme.surfaceElevated,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      items: [
        _item(RecipientSegment.all, 'All Members', Icons.group_outlined),
        _item(RecipientSegment.department, 'By Department', Icons.business_outlined),
        _item(RecipientSegment.group, 'By Group / Fellowship', Icons.home_work_outlined),
        _item(RecipientSegment.gender, 'By Gender', Icons.people_outline),
        _item(RecipientSegment.branch, 'By Branch', Icons.account_tree_outlined),
      ],
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }

  DropdownMenuItem<RecipientSegment> _item(RecipientSegment v, String label, IconData icon) {
    return DropdownMenuItem<RecipientSegment>(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 15, color: CmsTheme.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Filter Dropdown (dynamic based on segment) ───────────────────────────────

class _FilterDropdown extends ConsumerWidget {
  const _FilterDropdown({
    required this.segment,
    required this.value,
    required this.onChanged,
    required this.branchId,
  });

  final RecipientSegment segment;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (segment == RecipientSegment.gender) {
      return DropdownButtonFormField<String>(
        value: value,
        dropdownColor: CmsTheme.surfaceElevated,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: 'Select gender…',
        ),
        items: ['Male', 'Female']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: onChanged,
      );
    }

    if (segment == RecipientSegment.department) {
      final depts = ref.watch(departmentRepositoryProvider).watchDepartments(branchId);
      return StreamBuilder(
        stream: depts,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return DropdownButtonFormField<String>(
            value: value,
            dropdownColor: CmsTheme.surfaceElevated,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Select department…',
            ),
            items: items
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: onChanged,
          );
        },
      );
    }

    if (segment == RecipientSegment.group) {
      final groups = ref.watch(subGroupRepositoryProvider).watchSubGroups(branchId);
      return StreamBuilder(
        stream: groups,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return DropdownButtonFormField<String>(
            value: value,
            dropdownColor: CmsTheme.surfaceElevated,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Select group…',
            ),
            items: items
                .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                .toList(),
            onChanged: onChanged,
          );
        },
      );
    }

    if (segment == RecipientSegment.branch) {
      final branches = ref.watch(branchRepositoryProvider).watchBranches();
      return StreamBuilder(
        stream: branches,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return DropdownButtonFormField<String>(
            value: value,
            dropdownColor: CmsTheme.surfaceElevated,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Select branch…',
            ),
            items: items
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: onChanged,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Config Warning ───────────────────────────────────────────────────────────

class _ConfigWarning extends ConsumerWidget {
  const _ConfigWarning({required this.channel});

  final MessageChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(_commSettingsProvider);
    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) {
        bool configured;
        String label;
        switch (channel) {
          case MessageChannel.sms:
            configured = settings.hasSmsConfig;
            label = 'Termii API key';
            break;
          case MessageChannel.whatsapp:
            configured = settings.hasWhatsAppConfig;
            label = 'Termii WhatsApp config';
            break;
          case MessageChannel.push:
            configured = settings.hasPushConfig;
            label = 'FCM Server Key';
            break;
          case MessageChannel.email:
            configured = settings.hasEmailConfig;
            label = 'Resend API key';
            break;
        }

        if (configured) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CmsTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: CmsTheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label not configured. Go to Settings → Communication Integrations to set it up.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: CmsTheme.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── History Panel (Omnichannel) ──────────────────────────────────────────────

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel({
    required this.branchId,
    required this.selectedMessage,
    required this.onMessageSelected,
  });

  final String branchId;
  final MessageModel? selectedMessage;
  final ValueChanged<MessageModel?> onMessageSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(_messagesProvider(branchId));

    return Container(
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CmsTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CmsTheme.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_outlined, color: CmsTheme.info, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Broadcast Message History',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                messagesAsync.whenOrNull(
                      data: (msgs) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CmsTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${msgs.length}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CmsTheme.textSecondary,
                          ),
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: CmsTheme.surfaceElevated.withValues(alpha: 0.5),
            child: const Row(
              children: [
                _ColHeader('Channel', flex: 2),
                _ColHeader('Recipients', flex: 2),
                _ColHeader('Preview', flex: 5),
                _ColHeader('Status', flex: 2),
                _ColHeader('Sent At', flex: 3),
                _ColHeader('By', flex: 2),
              ],
            ),
          ),

          // Table rows
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: CmsTheme.accent),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: CmsTheme.danger, fontFamily: 'Inter')),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: CmsTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No messages sent yet',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: CmsTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use the compose panel to reach your members.',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: CmsTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: messages.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CmsTheme.border),
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isSelected = selectedMessage?.id == msg.id;
                    return _MessageRow(
                      message: msg,
                      isSelected: isSelected,
                      onTap: () => onMessageSelected(isSelected ? null : msg),
                    );
                  },
                );
              },
            ),
          ),

          // Detail panel (slide-in when a message is selected)
          if (selectedMessage != null)
            _MessageDetail(
              message: selectedMessage!,
              onClose: () => onMessageSelected(null),
            ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label, {this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CmsTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isSelected,
    required this.onTap,
  });

  final MessageModel message;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected
            ? CmsTheme.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(flex: 2, child: _ChannelChip(message.channel)),
            Expanded(
              flex: 2,
              child: Text(
                '${message.recipientCount} recipients',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: CmsTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.subject != null)
                    Text(
                      message.subject!,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    message.body,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: CmsTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _StatusChip(message.status)),
            Expanded(
              flex: 3,
              child: Text(
                message.sentAt != null
                    ? DateFormat('dd MMM, HH:mm').format(message.sentAt!)
                    : DateFormat('dd MMM, HH:mm').format(message.createdAt),
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: CmsTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                message.createdByName,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: CmsTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Detail Slide-In ──────────────────────────────────────────────────

class _MessageDetail extends StatelessWidget {
  const _MessageDetail({required this.message, required this.onClose});

  final MessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: const BoxDecoration(
          color: CmsTheme.surfaceElevated,
          border: Border(top: BorderSide(color: CmsTheme.border)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChannelChip(message.channel),
                const SizedBox(width: 10),
                _StatusChip(message.status),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: CmsTheme.textSecondary),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (message.subject != null) ...[
              _DetailRow('Subject', message.subject!),
              const SizedBox(height: 6),
            ],
            _DetailRow(
              'Recipients',
              '${message.recipientSegment.name.toUpperCase()} ${message.recipientFilter != null ? '(${message.recipientFilter})' : ''} — ${message.recipientCount} total',
            ),
            const SizedBox(height: 6),
            _DetailRow(
              'Delivery',
              '${message.sentCount} sent • ${message.failedCount} failed',
            ),
            const SizedBox(height: 10),
            const Text(
              'MESSAGE',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.textMuted,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CmsTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CmsTheme.border),
              ),
              child: SelectableText(
                message.body,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: CmsTheme.textPrimary),
              ),
            ),
            if (message.failedRecipients != null &&
                message.failedRecipients!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'FAILED RECIPIENTS',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CmsTheme.danger,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: message.failedRecipients!
                    .take(20)
                    .map((r) => GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: r));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: CmsTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: CmsTheme.danger.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              r,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: CmsTheme.danger),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: CmsTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ─── Reusable chips ───────────────────────────────────────────────────────────

class _ChannelChip extends StatelessWidget {
  const _ChannelChip(this.channel);

  final MessageChannel channel;

  @override
  Widget build(BuildContext context) {
    final color = switch (channel) {
      MessageChannel.sms => CmsTheme.info,
      MessageChannel.push => CmsTheme.accent,
      MessageChannel.email => CmsTheme.warning,
      MessageChannel.whatsapp => const Color(0xFF25D366),
    };
    final icon = switch (channel) {
      MessageChannel.sms => Icons.sms_outlined,
      MessageChannel.push => Icons.notifications_outlined,
      MessageChannel.email => Icons.email_outlined,
      MessageChannel.whatsapp => Icons.chat_bubble_outline,
    };
    final label = switch (channel) {
      MessageChannel.sms => 'SMS',
      MessageChannel.push => 'Push',
      MessageChannel.email => 'Email',
      MessageChannel.whatsapp => 'WhatsApp',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      MessageStatus.sent => (CmsTheme.success, 'Sent', Icons.check_circle_outline),
      MessageStatus.sending => (CmsTheme.warning, 'Sending', Icons.sync_outlined),
      MessageStatus.partial => (CmsTheme.warning, 'Partial', Icons.warning_amber_outlined),
      MessageStatus.failed => (CmsTheme.danger, 'Failed', Icons.error_outline),
      MessageStatus.draft => (CmsTheme.textMuted, 'Draft', Icons.drafts_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == MessageStatus.sending
              ? SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
              : Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: CmsTheme.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
