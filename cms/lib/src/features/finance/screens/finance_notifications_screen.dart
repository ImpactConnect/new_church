import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _notificationsProvider =
    StreamProvider.autoDispose.family<List<FinanceNotificationModel>, (String, String)>(
  (ref, params) =>
      ref.watch(financeRepositoryProvider).watchNotifications(params.$1, params.$2),
);

class FinanceNotificationsScreen extends ConsumerWidget {
  const FinanceNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    if (user == null) return const SizedBox.shrink();

    final notifAsync = ref.watch(_notificationsProvider((branchId, user.uid)));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CmsPageHeader(
            title: 'Finance Notifications',
            subtitle: 'Approval outcomes and change alerts for your financial requests',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: notifAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const CmsEmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'No notifications yet',
                    subtitle: 'Approval updates for your budget and expenditure requests will appear here.',
                  );
                }
                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _NotificationCard(
                    notif: notifications[i],
                    branchId: branchId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notif, required this.branchId});
  final FinanceNotificationModel notif;
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChange = notif.type.contains('with-changes');
    final isRejected = notif.type.contains('rejected');

    final Color accentColor = isRejected
        ? CmsTheme.danger
        : isChange
            ? CmsTheme.warning
            : CmsTheme.success;

    final IconData icon = isRejected
        ? Icons.cancel_outlined
        : isChange
            ? Icons.edit_note_outlined
            : Icons.check_circle_outline;

    final String typeLabel = isRejected
        ? 'Rejected'
        : isChange
            ? 'Approved with Changes'
            : 'Approved';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: notif.read ? CmsTheme.surface : accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.read ? CmsTheme.border : accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      _formatDate(notif.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: CmsTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notif.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            notif.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: CmsTheme.textPrimary,
            ),
          ),
          // DiffViewer — only if there are changes to show
          if (notif.changesSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            DiffViewer(changes: notif.changesSummary),
          ],
          // Mark as read
          if (!notif.read) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await ref
                      .read(financeRepositoryProvider)
                      .markNotificationRead(branchId, notif.id);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'Mark as read',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: CmsTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
