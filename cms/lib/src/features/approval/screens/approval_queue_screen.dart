import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _pendingAnnouncementsProvider = StreamProvider.autoDispose.family<List<AnnouncementModel>, String>(
  (ref, branchId) => ref.watch(announcementRepositoryProvider).watchAnnouncements(branchId, status: 'pending'),
);

final _pendingBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId, status: 'pending'),
);

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final pendingAnnouncementsAsync = ref.watch(_pendingAnnouncementsProvider(branchId));
    final pendingBudgetsAsync = ref.watch(_pendingBudgetsProvider(branchId));

    final canApproveAnnounce = user?.can(AppPermission.approveAnnouncement) ?? false;
    final canApproveBudget = user?.can(AppPermission.approveBudget) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CmsPageHeader(
            title: 'Approval Queue',
            subtitle: 'Unified inbox for pending church approvals',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canApproveAnnounce) ...[
                    _sectionHeader('Pending Announcements'),
                    const SizedBox(height: 12),
                    pendingAnnouncementsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _emptyCard('No pending announcements to review.');
                        }
                        return Column(
                          children: list.map((a) => _AnnouncementApprovalItem(
                            item: a,
                            branchId: branchId,
                            user: user,
                            ref: ref,
                          )).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (canApproveBudget) ...[
                    _sectionHeader('Pending Budget Requests'),
                    const SizedBox(height: 12),
                    pendingBudgetsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _emptyCard('No pending budget requests to review.');
                        }
                        return Column(
                          children: list.map((b) => _BudgetApprovalItem(
                            budget: b,
                            branchId: branchId,
                            user: user,
                            ref: ref,
                          )).toList(),
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
    child: Text(msg, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
  );
}

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
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
              ),
              const Spacer(),
              Text('Audience: ${item.targetAudience.toUpperCase()}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.content, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Requested by ${item.requestedByName}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
              const Spacer(),
              CmsButton(
                label: 'Reject',
                compact: true,
                variant: CmsButtonVariant.danger,
                onPressed: () async {
                  await ref.read(announcementRepositoryProvider).rejectAnnouncement(branchId, item.id, 'Rejected by Lead Pastor');
                },
              ),
              const SizedBox(width: 8),
              CmsButton(
                label: 'Approve',
                icon: Icons.check,
                compact: true,
                onPressed: () async {
                  await ref.read(announcementRepositoryProvider).approveAnnouncement(
                    branchId, item.id, user.uid, user.displayName ?? user.email,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    // Segregation of duties: approver cannot be the requester
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
              Text(
                budget.category,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
              ),
              const Spacer(),
              Text(
                '₦${budget.requestedAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: CmsTheme.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Fiscal Period: ${budget.fiscalPeriod}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Requested by ${budget.requestedBy}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
              if (isRequester) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CmsTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Segregation of duties: Cannot approve your own request',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.danger, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const Spacer(),
              if (!isRequester) ...[
                CmsButton(
                  label: 'Reject',
                  compact: true,
                  variant: CmsButtonVariant.danger,
                  onPressed: () async {
                    await ref.read(financeRepositoryProvider).rejectBudget(branchId, budget.id, 'Rejected');
                  },
                ),
                const SizedBox(width: 8),
                CmsButton(
                  label: 'Approve Budget',
                  icon: Icons.check,
                  compact: true,
                  onPressed: () async {
                    await ref.read(financeRepositoryProvider).approveBudget(
                      branchId, budget.id, user.uid, user.displayName ?? user.email,
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
