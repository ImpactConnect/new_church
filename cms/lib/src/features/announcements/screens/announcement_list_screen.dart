import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';

final _announcementsProvider = StreamProvider.autoDispose.family<List<AnnouncementModel>, String>(
  (ref, branchId) => ref.watch(announcementRepositoryProvider).watchAnnouncements(branchId),
);

class AnnouncementListScreen extends ConsumerWidget {
  const AnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final announcementsAsync = ref.watch(_announcementsProvider(branchId));

    final canCreate = user?.can(AppPermission.createAnnouncement) ?? false;
    final canApprove = user?.can(AppPermission.approveAnnouncement) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Announcements',
            subtitle: 'Draft and publish official church bulletins',
            actions: [
              if (canCreate)
                CmsButton(
                  label: 'New Announcement',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showDraftDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: announcementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (list) {
                if (list.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No announcements yet',
                    subtitle: 'Draft announcements for Lead Pastor review.',
                    action: canCreate
                        ? CmsButton(
                            label: 'New Announcement',
                            icon: Icons.add,
                            onPressed: () => _showDraftDialog(context, ref, branchId, user!),
                          )
                        : null,
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AnnouncementCard(
                    item: list[i],
                    canApprove: canApprove,
                    onApprove: () async {
                      await ref.read(announcementRepositoryProvider).approveAnnouncement(
                        branchId, list[i].id, user!.uid, user.displayName ?? user.email,
                      );
                    },
                    onReject: () async {
                      final reasonCtrl = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: CmsTheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: CmsTheme.border),
                          ),
                          title: const Text('Reject Announcement', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                          content: TextField(
                            controller: reasonCtrl,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'Enter reason for rejection…'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: CmsTheme.danger),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (ok) {
                        await ref.read(announcementRepositoryProvider).rejectAnnouncement(
                          branchId, list[i].id, reasonCtrl.text.trim(),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDraftDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _AnnouncementFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.canApprove,
    required this.onApprove,
    required this.onReject,
  });

  final AnnouncementModel item;
  final bool canApprove;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(item.status),
              const SizedBox(width: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Audience: ${item.targetAudience.toUpperCase()}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Drafted by ${item.requestedByName}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
              ),
              const Spacer(),
              if (canApprove && item.status == 'pending') ...[
                CmsButton(
                  label: 'Reject',
                  compact: true,
                  variant: CmsButtonVariant.danger,
                  onPressed: onReject,
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Approve',
                  icon: Icons.check,
                  compact: true,
                  onPressed: onApprove,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _audience = 'all';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Draft Announcement', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Target Audience', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Entire Church')),
                  DropdownMenuItem(value: 'youth', child: Text('Youth Ministry')),
                  DropdownMenuItem(value: 'choir', child: Text('Choir Department')),
                  DropdownMenuItem(value: 'ushers', child: Text('Ushering Team')),
                ],
                onChanged: (v) => setState(() => _audience = v!),
              ),
              const SizedBox(height: 16),
              const Text('Content', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 4,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Submit for Approval',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final model = AnnouncementModel(
                id: '',
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text.trim(),
                targetAudience: _audience,
                status: 'pending',
                requestedBy: widget.user.uid,
                requestedByName: widget.user.displayName ?? widget.user.email,
                createdAt: DateTime.now(),
              );
              await widget.ref.read(announcementRepositoryProvider).createAnnouncement(widget.branchId, model);
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                );
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}
