import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';

final _pendingAnnouncementsProvider =
    StreamProvider.autoDispose.family<List<AnnouncementModel>, String>(
  (ref, branchId) =>
      ref.watch(announcementRepositoryProvider).watchAnnouncements(branchId, status: 'pending'),
);

final _pendingBudgetsProvider =
    StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) =>
      ref.watch(financeRepositoryProvider).watchBudgets(branchId, status: 'pending'),
);

final _pendingExpendituresProvider =
    StreamProvider.autoDispose.family<List<ExpenditureRequestModel>, String>(
  (ref, branchId) =>
      ref.watch(financeRepositoryProvider).watchExpenditureRequests(branchId, status: 'pending'),
);

final _pendingEventsProvider =
    StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId).map(
        (list) => list.where((e) => e.isPending).toList(),
      ),
);

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final pendingAnnouncementsAsync = ref.watch(_pendingAnnouncementsProvider(branchId));
    final pendingBudgetsAsync = ref.watch(_pendingBudgetsProvider(branchId));
    final pendingExpendituresAsync = ref.watch(_pendingExpendituresProvider(branchId));
    final pendingEventsAsync = ref.watch(_pendingEventsProvider(branchId));

    final canApproveAnnounce = user?.can(AppPermission.approveAnnouncement) ?? false;
    final canApproveBudget = user?.can(AppPermission.approveBudget) ?? false;
    final canApproveExpenditure = user?.can(AppPermission.approveExpenditure) ?? false;
    final isLeadPastorOrAdmin = user?.roleId == AppRole.leadPastor || user?.roleId == 'admin';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CmsPageHeader(
            title: 'Approval Queue',
            subtitle: 'Unified inbox for pending approvals — events, master calendar, announcements, budgets, and expenditures',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Church Events & Calendar ──────────────────────────────
                  if (isLeadPastorOrAdmin) ...[
                    _sectionHeader('Pending Church Events & Master Calendar'),
                    const SizedBox(height: 12),
                    pendingEventsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) return _emptyCard('No pending church events for approval.');
                        return Column(
                          children: list.map((e) => _EventApprovalItem(event: e, branchId: branchId, ref: ref)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Announcements ───────────────────────────────────────────
                  if (canApproveAnnounce) ...[
                    _sectionHeader('Pending Announcements'),
                    const SizedBox(height: 12),
                    pendingAnnouncementsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e',
                          style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) return _emptyCard('No pending announcements.');
                        return Column(
                          children: list
                              .map((a) => _AnnouncementApprovalItem(
                                    item: a,
                                    branchId: branchId,
                                    user: user,
                                    ref: ref,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Budget Requests ──────────────────────────────────────────
                  if (canApproveBudget) ...[
                    _sectionHeader('Pending Budget Requests'),
                    const SizedBox(height: 12),
                    pendingBudgetsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e',
                          style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) return _emptyCard('No pending budget requests.');
                        return Column(
                          children: list
                              .map((b) => _BudgetApprovalItem(
                                    budget: b,
                                    branchId: branchId,
                                    user: user,
                                    ref: ref,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Expenditure Requests ─────────────────────────────────────
                  if (canApproveExpenditure) ...[
                    _sectionHeader('Pending Expenditure Requests'),
                    const SizedBox(height: 12),
                    pendingExpendituresAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e',
                          style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _emptyCard('No pending expenditure requests.');
                        }
                        return Column(
                          children: list
                              .map((r) => _ExpenditureApprovalItem(
                                    request: r,
                                    branchId: branchId,
                                    user: user,
                                    ref: ref,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CmsTheme.textPrimary,
        ),
      );

  Widget _emptyCard(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Text(msg,
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
      );
}

// ── Announcement Item ─────────────────────────────────────────────────────────

class _AnnouncementApprovalItem extends StatelessWidget {
  const _AnnouncementApprovalItem({
    required this.item,
    required this.branchId,
    required this.user,
    required this.ref,
  });

  final AnnouncementModel item;
  final String branchId;
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              const StatusBadge('pending'),
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
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.content,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Requested by ${item.requestedByName}',
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
              const Spacer(),
              CmsButton(
                label: 'Reject',
                compact: true,
                variant: CmsButtonVariant.danger,
                onPressed: () async {
                  final reason = await showRejectionReasonDialog(context);
                  if (reason == null || !context.mounted) return;
                  await ref
                      .read(announcementRepositoryProvider)
                      .rejectAnnouncement(branchId, item.id, reason);
                },
              ),
              const SizedBox(width: 8),
              CmsButton(
                label: 'Approve',
                icon: Icons.check,
                compact: true,
                onPressed: () async {
                  await ref.read(announcementRepositoryProvider).approveAnnouncement(
                        branchId, item.id, user.uid, user.displayName ?? user.email);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Budget Item ───────────────────────────────────────────────────────────────

class _BudgetApprovalItem extends StatelessWidget {
  const _BudgetApprovalItem({
    required this.budget,
    required this.branchId,
    required this.user,
    required this.ref,
  });

  final BudgetModel budget;
  final String branchId;
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isRequester = user?.uid == budget.requestedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              const StatusBadge('pending'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  budget.category,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '₦${budget.requestedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Fiscal Period: ${budget.fiscalPeriod}',
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
          ),
          if (budget.requestedDescription != null &&
              budget.requestedDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              budget.requestedDescription!,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          if (isRequester)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CmsTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Segregation of duties: Cannot approve your own request',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, color: CmsTheme.danger),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CmsButton(
                  label: 'Reject',
                  compact: true,
                  variant: CmsButtonVariant.danger,
                  onPressed: () async {
                    final reason = await showRejectionReasonDialog(context);
                    if (reason == null || !context.mounted) return;
                    await ref
                        .read(financeRepositoryProvider)
                        .rejectBudget(branchId, budget.id, reason);
                  },
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Edit & Approve',
                  icon: Icons.edit_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () => _showEditApproveDialog(context, ref),
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Approve',
                  icon: Icons.check,
                  compact: true,
                  onPressed: () async {
                    await ref.read(financeRepositoryProvider).approveBudget(
                          branchId, budget.id, user.uid, user.displayName ?? user.email);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showEditApproveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _EditApproveBudgetDialog(
        budget: budget,
        branchId: branchId,
        user: user,
        ref: ref,
      ),
    );
  }
}

class _EditApproveBudgetDialog extends StatefulWidget {
  const _EditApproveBudgetDialog({
    required this.budget,
    required this.branchId,
    required this.user,
    required this.ref,
  });
  final BudgetModel budget;
  final String branchId;
  final dynamic user;
  final WidgetRef ref;

  @override
  State<_EditApproveBudgetDialog> createState() => _EditApproveBudgetDialogState();
}

class _EditApproveBudgetDialogState extends State<_EditApproveBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amtCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amtCtrl = TextEditingController(
        text: widget.budget.requestedAmount.toStringAsFixed(2));
    _catCtrl = TextEditingController(text: widget.budget.category);
    _descCtrl = TextEditingController(
        text: widget.budget.requestedDescription ?? '');
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
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
      title: const Text(
        'Edit & Approve Budget',
        style: TextStyle(
          fontFamily: 'Inter',
          color: CmsTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust fields as needed before approving. A diff will be sent to Finance.',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _label('Category'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _label('Approved Amount (₦)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) =>
                    (double.tryParse(v ?? '') == null) ? 'Valid amount required' : null,
              ),
              const SizedBox(height: 14),
              _label('Description / Notes'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Approve',
          icon: Icons.check,
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              await widget.ref.read(financeRepositoryProvider).approveBudgetWithEdits(
                    widget.branchId,
                    widget.budget.id,
                    widget.user.uid,
                    widget.user.displayName ?? widget.user.email,
                    approvedAmount: double.parse(_amtCtrl.text.trim()),
                    approvedCategory: _catCtrl.text.trim(),
                    approvedDescription: _descCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CmsTheme.danger),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
      );
}

// ── Expenditure Request Item ──────────────────────────────────────────────────

class _ExpenditureApprovalItem extends StatelessWidget {
  const _ExpenditureApprovalItem({
    required this.request,
    required this.branchId,
    required this.user,
    required this.ref,
  });

  final ExpenditureRequestModel request;
  final String branchId;
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isRequester = user?.uid == request.requestedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              const StatusBadge('pending'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₦${request.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Category: ${request.category}',
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (isRequester)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CmsTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Segregation of duties: Cannot approve your own request',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, color: CmsTheme.danger),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CmsButton(
                  label: 'Reject',
                  compact: true,
                  variant: CmsButtonVariant.danger,
                  onPressed: () async {
                    final reason = await showRejectionReasonDialog(context);
                    if (reason == null || !context.mounted) return;
                    await ref
                        .read(financeRepositoryProvider)
                        .rejectExpenditure(branchId, request.id, reason);
                  },
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Edit & Approve',
                  icon: Icons.edit_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () => _showEditApproveDialog(context, ref),
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Approve',
                  icon: Icons.check,
                  compact: true,
                  onPressed: () async {
                    await ref.read(financeRepositoryProvider).approveExpenditure(
                          branchId, request.id, user.uid, user.displayName ?? user.email);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showEditApproveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _EditApproveExpenditureDialog(
        request: request,
        branchId: branchId,
        user: user,
        ref: ref,
      ),
    );
  }
}

class _EditApproveExpenditureDialog extends StatefulWidget {
  const _EditApproveExpenditureDialog({
    required this.request,
    required this.branchId,
    required this.user,
    required this.ref,
  });
  final ExpenditureRequestModel request;
  final String branchId;
  final dynamic user;
  final WidgetRef ref;

  @override
  State<_EditApproveExpenditureDialog> createState() =>
      _EditApproveExpenditureDialogState();
}

class _EditApproveExpenditureDialogState
    extends State<_EditApproveExpenditureDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amtCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amtCtrl =
        TextEditingController(text: widget.request.amount.toStringAsFixed(2));
    _catCtrl = TextEditingController(text: widget.request.category);
    _descCtrl = TextEditingController(text: widget.request.description);
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
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
      title: const Text(
        'Edit & Approve Expenditure',
        style: TextStyle(
            fontFamily: 'Inter',
            color: CmsTheme.textPrimary,
            fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust the fields below. Finance will receive a notification showing exactly what changed.',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _label('Category'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catCtrl,
                style: const TextStyle(
                    color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _label('Approved Amount (₦)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amtCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) =>
                    (double.tryParse(v ?? '') == null) ? 'Valid amount required' : null,
              ),
              const SizedBox(height: 14),
              _label('Description / Purpose'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(
                    color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Approve',
          icon: Icons.check,
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              await widget.ref
                  .read(financeRepositoryProvider)
                  .approveExpenditureWithEdits(
                    widget.branchId,
                    widget.request.id,
                    widget.user.uid,
                    widget.user.displayName ?? widget.user.email,
                    approvedAmount: double.parse(_amtCtrl.text.trim()),
                    approvedCategory: _catCtrl.text.trim(),
                    approvedDescription: _descCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CmsTheme.danger),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
      );
}

// ── Event Approval Item ────────────────────────────────────────────────────────

class _EventApprovalItem extends StatelessWidget {
  const _EventApprovalItem({
    required this.event,
    required this.branchId,
    required this.ref,
  });

  final EventModel event;
  final String branchId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge('pending'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CmsTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.eventType.toUpperCase(),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${DateFormat('EEEE, MMM d, yyyy').format(event.effectiveStartDate)} | Venue: ${event.location}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(event.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Submitted by ${event.createdByName ?? "Secretary"}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
              ),
              const Spacer(),
              CmsButton(
                label: 'Reject',
                compact: true,
                variant: CmsButtonVariant.danger,
                onPressed: () async {
                  final reason = await showRejectionReasonDialog(context);
                  if (reason == null || !context.mounted) return;
                  await ref.read(eventRepositoryProvider).rejectEvent(branchId, event.id, reason);
                },
              ),
              const SizedBox(width: 8),
              CmsButton(
                label: 'Approve Event',
                icon: Icons.check,
                compact: true,
                onPressed: () async {
                  await ref.read(eventRepositoryProvider).approveEvent(branchId, event.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Approved "${event.title}"'), backgroundColor: CmsTheme.success),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
