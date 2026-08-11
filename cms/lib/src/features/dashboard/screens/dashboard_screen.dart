import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/routing/app_router.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';

final _dashboardMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

final _dashboardIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

final _dashboardEventsProvider = StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId),
);

final _dashboardPendingAnnounceProvider = StreamProvider.autoDispose.family<List<AnnouncementModel>, String>(
  (ref, branchId) => ref.watch(announcementRepositoryProvider).watchAnnouncements(branchId, status: 'pending'),
);

final _dashboardPendingBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId, status: 'pending'),
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(cmsUserProvider);
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading dashboard')),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _RoleDashboard(user: user);
      },
    );
  }
}

class _RoleDashboard extends ConsumerWidget {
  const _RoleDashboard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user.displayName ?? user.email.split('@').first}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CmsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roleGreeting(user.roleId),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: CmsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: CmsTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CmsTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _roleLabel(user.roleId),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Live Stat Grid
          _StatGrid(user: user),
          const SizedBox(height: 32),
          // Quick actions
          _QuickActions(user: user),
          const SizedBox(height: 32),
          // System Status Notice
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: CmsTheme.success, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Core CMS Modules Active',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Member records, secretariat, financial ledger, asset inventory, and reporting streams are online and connected.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: CmsTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleGreeting(String roleId) => switch (roleId) {
    'leadPastor' => 'Here\'s your cross-branch executive overview for today.',
    'secretary' => 'Here\'s your upcoming events, member roster, and secretariat inbox.',
    'financeDept' => 'Here\'s your budget, income streams, and disbursement ledger.',
    _ => 'Welcome to the Church Management System.',
  };

  String _roleLabel(String roleId) => switch (roleId) {
    'leadPastor' => 'Lead Pastor',
    'secretary' => 'Secretary',
    'financeDept' => 'Finance Dept',
    _ => roleId,
  };
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);

    final membersAsync = ref.watch(_dashboardMembersProvider(branchId));
    final incomeAsync = ref.watch(_dashboardIncomeProvider(branchId));
    final eventsAsync = ref.watch(_dashboardEventsProvider(branchId));
    final pendingAnnounceAsync = ref.watch(_dashboardPendingAnnounceProvider(branchId));
    final pendingBudgetsAsync = ref.watch(_dashboardPendingBudgetsProvider(branchId));

    final totalMembers = membersAsync.when(data: (m) => '${m.length}', loading: () => '…', error: (_, __) => '—');
    final totalIncome = incomeAsync.when(data: (inc) => '₦${inc.fold<double>(0, (s, i) => s + i.amount).toStringAsFixed(0)}', loading: () => '…', error: (_, __) => '—');
    final lastAttendance = eventsAsync.when(data: (evs) => evs.isNotEmpty ? '${evs.first.headcount}' : '0', loading: () => '…', error: (_, __) => '—');
    final pendingCount = (pendingAnnounceAsync.valueOrNull?.length ?? 0) + (pendingBudgetsAsync.valueOrNull?.length ?? 0);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: _StatCard(
            label: 'Total Members',
            value: totalMembers,
            icon: Icons.people_outline,
            color: CmsTheme.accent,
          ),
        ),
        SizedBox(
          width: 220,
          child: _StatCard(
            label: 'Total Revenue',
            value: totalIncome,
            icon: Icons.trending_up_outlined,
            color: CmsTheme.success,
          ),
        ),
        SizedBox(
          width: 220,
          child: _StatCard(
            label: 'Pending Approvals',
            value: '$pendingCount',
            icon: Icons.pending_actions_outlined,
            color: pendingCount > 0 ? CmsTheme.warning : CmsTheme.textMuted,
          ),
        ),
        SizedBox(
          width: 220,
          child: _StatCard(
            label: 'Last Service Headcount',
            value: lastAttendance,
            icon: Icons.how_to_reg_outlined,
            color: CmsTheme.info,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: CmsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: CmsTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CmsTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (user.can(AppPermission.manageMembers))
              _ActionChip(
                icon: Icons.person_add_outlined,
                label: 'Members',
                onTap: () => context.go(AppRoutes.members),
              ),
            if (user.can(AppPermission.recordAttendance))
              _ActionChip(
                icon: Icons.how_to_reg_outlined,
                label: 'Events & Attendance',
                onTap: () => context.go(AppRoutes.events),
              ),
            if (user.can(AppPermission.createAnnouncement))
              _ActionChip(
                icon: Icons.campaign_outlined,
                label: 'Announcements',
                onTap: () => context.go(AppRoutes.announcements),
              ),
            if (user.can(AppPermission.recordIncome))
              _ActionChip(
                icon: Icons.add_card_outlined,
                label: 'Record Revenue',
                onTap: () => context.go(AppRoutes.income),
              ),
            if (user.can(AppPermission.createBudgetRequest))
              _ActionChip(
                icon: Icons.request_page_outlined,
                label: 'Budgets',
                onTap: () => context.go(AppRoutes.budgets),
              ),
            if (user.can(AppPermission.createExpenditureRequest))
              _ActionChip(
                icon: Icons.receipt_long_outlined,
                label: 'Expenditures',
                onTap: () => context.go(AppRoutes.expenditures),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CmsTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: CmsTheme.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CmsTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
