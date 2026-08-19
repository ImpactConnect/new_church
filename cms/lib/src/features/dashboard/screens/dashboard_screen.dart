import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/routing/app_router.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';
import 'package:cms/src/features/departments/models/department_model.dart';
import 'package:cms/src/features/correspondence/models/correspondence_model.dart';
import 'package:cms/src/features/members/screens/member_form_screen.dart';
import 'package:cms/src/features/members/screens/member_import_screen.dart';

// ─── Data Providers ──────────────────────────────────────────────────────────

final _dashboardMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

final _dashboardIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

final _dashboardGivingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);

final _dashboardBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId),
);

final _dashboardExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
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

final _dashboardPendingExpRequestsProvider = StreamProvider.autoDispose.family<List<ExpenditureRequestModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditureRequests(branchId, status: 'pending'),
);

final _dashboardDepartmentsProvider = StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) => ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

final _dashboardCorrespondenceProvider = StreamProvider.autoDispose.family<List<CorrespondenceModel>, String>(
  (ref, branchId) => ref.watch(correspondenceRepositoryProvider).watchCorrespondence(branchId),
);

final _dashboardNotificationsProvider = StreamProvider.autoDispose.family<List<FinanceNotificationModel>, (String, String)>(
  (ref, params) => ref.watch(financeRepositoryProvider).watchNotifications(params.$1, params.$2),
);

// ─── Entry Point Widget ──────────────────────────────────────────────────────

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
        return _RoleDashboardSwitch(user: user);
      },
    );
  }
}

class _RoleDashboardSwitch extends ConsumerWidget {
  const _RoleDashboardSwitch({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (user.roleId) {
      AppRole.secretary => _SecretaryDashboard(user: user),
      AppRole.financeDept => _FinanceDeptDashboard(user: user),
      _ => _PastorDashboard(user: user),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 👑 1. LEAD PASTOR DASHBOARD (Executive & Governance Oversight)
// ─────────────────────────────────────────────────────────────────────────────

class _PastorDashboard extends ConsumerWidget {
  const _PastorDashboard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);

    final membersAsync = ref.watch(_dashboardMembersProvider(branchId));
    final incomeAsync = ref.watch(_dashboardIncomeProvider(branchId));
    final givingAsync = ref.watch(_dashboardGivingProvider(branchId));
    final expendituresAsync = ref.watch(_dashboardExpendituresProvider(branchId));
    final eventsAsync = ref.watch(_dashboardEventsProvider(branchId));
    final pendingAnnounceAsync = ref.watch(_dashboardPendingAnnounceProvider(branchId));
    final pendingBudgetsAsync = ref.watch(_dashboardPendingBudgetsProvider(branchId));
    final pendingExpAsync = ref.watch(_dashboardPendingExpRequestsProvider(branchId));
    final deptsAsync = ref.watch(_dashboardDepartmentsProvider(branchId));

    final totalMembers = membersAsync.valueOrNull?.length ?? 0;
    final totalGenInc = incomeAsync.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final totalGiv = givingAsync.valueOrNull?.fold<double>(0, (s, g) => s + g.amount) ?? 0;
    final totalRevenue = totalGenInc + totalGiv;
    final totalApprovedExp = expendituresAsync.valueOrNull?.fold<double>(0, (s, e) => s + e.approvedAmount) ?? 0;
    final netCash = totalRevenue - totalApprovedExp;

    final pendingAnnounce = pendingAnnounceAsync.valueOrNull ?? [];
    final pendingBudgets = pendingBudgetsAsync.valueOrNull ?? [];
    final pendingExp = pendingExpAsync.valueOrNull ?? [];
    final pendingTotal = pendingAnnounce.length + pendingBudgets.length + pendingExp.length;

    final lastService = eventsAsync.valueOrNull?.firstOrNull;
    final totalDepts = deptsAsync.valueOrNull?.length ?? 0;

    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleHeader(
            user: user,
            title: 'Executive Governance & Growth Overview',
            roleName: 'Lead Pastor',
            roleColor: CmsTheme.accent,
          ),
          const SizedBox(height: 20),

          // ── 1. Top Quick Executive Actions Card ───────────────────────────
          CmsCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: CmsTheme.accent, size: 20),
                const SizedBox(width: 10),
                const Text('Quick Actions:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      CmsButton(
                        label: 'Approval Queue (${pendingTotal})',
                        icon: Icons.approval_outlined,
                        compact: true,
                        onPressed: () => context.go(AppRoutes.approvalQueue),
                      ),
                      CmsButton(
                        label: 'Finance Overview',
                        icon: Icons.dashboard_customize_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.financeDashboard),
                      ),
                      CmsButton(
                        label: 'Announcements',
                        icon: Icons.campaign_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.announcements),
                      ),
                      CmsButton(
                        label: 'Branch Churches',
                        icon: Icons.account_tree_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.branches),
                      ),
                      CmsButton(
                        label: 'Audit Log',
                        icon: Icons.history_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.auditLog),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── 2. Pastor KPI Summary Row ────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Pending Authorizations',
                value: '$pendingTotal',
                subtitle: '${pendingAnnounce.length} announce, ${pendingBudgets.length} budget, ${pendingExp.length} exp',
                icon: Icons.pending_actions_outlined,
                color: pendingTotal > 0 ? CmsTheme.warning : CmsTheme.success,
                onTap: () => context.go(AppRoutes.approvalQueue),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Total Church Membership',
                value: '$totalMembers',
                subtitle: 'Active members registered',
                icon: Icons.people_outline,
                color: CmsTheme.accent,
                onTap: () => context.go(AppRoutes.members),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Net Cash Position',
                value: '${netCash >= 0 ? '+' : ''}${currencyFmt.format(netCash)}',
                subtitle: netCash >= 0 ? 'Surplus (Revenue > Exp)' : 'Deficit (Exp > Revenue)',
                icon: netCash >= 0 ? Icons.trending_up : Icons.warning_amber_rounded,
                color: netCash >= 0 ? CmsTheme.success : CmsTheme.danger,
                onTap: () => context.go(AppRoutes.financeDashboard),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Last Service Headcount',
                value: lastService != null ? '${lastService.headcount}' : '0',
                subtitle: lastService != null ? lastService.title : 'No recent service logged',
                icon: Icons.how_to_reg_outlined,
                color: CmsTheme.info,
                onTap: () => context.go(AppRoutes.attendance),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 3. Financial & Attendance Insights with Trend Charts ─────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Financial Trend Chart & Insight
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: CmsTheme.success, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Financial Trend & Cash Flow Insight', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                Text('6-month revenue vs expenditure trend pattern', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeDashboard),
                            child: const Text('Details →', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 190,
                        child: _PastorFinancialTrendChart(
                          income: incomeAsync.valueOrNull ?? [],
                          giving: givingAsync.valueOrNull ?? [],
                          expenditures: expendituresAsync.valueOrNull ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Attendance Trend Chart & Insight
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.show_chart, color: CmsTheme.info, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Attendance Growth & Service Patterns', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                Text('Service headcount progression & peak attendance', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.attendance),
                            child: const Text('Details →', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 190,
                        child: _PastorAttendanceTrendChart(
                          events: eventsAsync.valueOrNull ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 4. Pending Approvals (At least 3 items with View All / No pending approval) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pending_actions, color: CmsTheme.warning, size: 18),
                          const SizedBox(width: 8),
                          const Text('Pending Approvals', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context.go(AppRoutes.approvalQueue),
                            icon: const Icon(Icons.arrow_forward, size: 14),
                            label: const Text('View All', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (pendingTotal == 0)
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.check_circle_outline, color: CmsTheme.success, size: 36),
                                SizedBox(height: 8),
                                Text('No pending approval', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                                SizedBox(height: 4),
                                Text('All submitted announcements, budgets, and expenditure requests have been authorized.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Display at least 3 pending items (announcements, budgets, expenditures)
                        ..._buildPastorPendingItems(
                          branchId: branchId,
                          user: user,
                          ref: ref,
                          context: context,
                          pendingAnnounce: pendingAnnounce,
                          pendingBudgets: pendingBudgets,
                          pendingExp: pendingExp,
                        ).take(3),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Pastoral Care & Ministry Groups Summary
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const _WeeklyCelebrationsCard(),
                    const SizedBox(height: 16),
                    CmsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Ministry Departments & Units', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                              const Spacer(),
                              Text('$totalDepts Active', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('View church groups and member rosters in view-only mode.', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 12),
                          CmsButton(
                            label: 'View Departments Roster',
                            icon: Icons.groups_outlined,
                            variant: CmsButtonVariant.secondary,
                            compact: true,
                            onPressed: () => context.go(AppRoutes.departments),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPastorPendingItems({
    required String branchId,
    required dynamic user,
    required WidgetRef ref,
    required BuildContext context,
    required List<AnnouncementModel> pendingAnnounce,
    required List<BudgetModel> pendingBudgets,
    required List<ExpenditureRequestModel> pendingExp,
  }) {
    final list = <Widget>[];

    for (final a in pendingAnnounce) {
      list.add(_buildApprovalItem(
        title: 'Announcement: ${a.title}',
        sub: 'Audience: ${a.targetAudience} · Requested by ${a.requestedByName}',
        amount: null,
        icon: Icons.campaign_outlined,
        onApprove: () => ref.read(announcementRepositoryProvider).approveAnnouncement(branchId, a.id, user.uid, user.displayName ?? user.email),
        onReject: () async {
          final reason = await showRejectionReasonDialog(context);
          if (reason != null) {
            await ref.read(announcementRepositoryProvider).rejectAnnouncement(branchId, a.id, reason);
          }
        },
      ));
    }

    for (final b in pendingBudgets) {
      list.add(_buildApprovalItem(
        title: 'Budget: ${b.category}',
        sub: '${b.fiscalPeriod} · Requested by Finance',
        amount: b.requestedAmount,
        icon: Icons.account_balance_wallet_outlined,
        onApprove: () => ref.read(financeRepositoryProvider).approveBudget(branchId, b.id, user.uid, user.displayName ?? user.email),
        onReject: () async {
          final reason = await showRejectionReasonDialog(context);
          if (reason != null) {
            await ref.read(financeRepositoryProvider).rejectBudget(branchId, b.id, reason);
          }
        },
      ));
    }

    for (final r in pendingExp) {
      list.add(_buildApprovalItem(
        title: 'Expenditure: ${r.description}',
        sub: 'Category: ${r.category}',
        amount: r.amount,
        icon: Icons.receipt_long_outlined,
        onApprove: () => ref.read(financeRepositoryProvider).approveExpenditure(branchId, r.id, user.uid, user.displayName ?? user.email),
        onReject: () async {
          final reason = await showRejectionReasonDialog(context);
          if (reason != null) {
            await ref.read(financeRepositoryProvider).rejectExpenditure(branchId, r.id, reason);
          }
        },
      ));
    }

    return list;
  }

  Widget _buildApprovalItem({
    required String title,
    required String sub,
    required double? amount,
    required IconData icon,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CmsTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CmsTheme.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                  Text(sub, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                ],
              ),
            ),
            if (amount != null) ...[
              Text(currencyFmt.format(amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.warning)),
              const SizedBox(width: 12),
            ],
            IconButton(
              icon: const Icon(Icons.close, color: CmsTheme.danger, size: 18),
              onPressed: onReject,
              tooltip: 'Reject',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: CmsTheme.success, size: 18),
              onPressed: onApprove,
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// 📝 2. SECRETARY DASHBOARD (Secretariat & Operations)
// ─────────────────────────────────────────────────────────────────────────────

class _SecretaryDashboard extends ConsumerWidget {
  const _SecretaryDashboard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);

    final membersAsync = ref.watch(_dashboardMembersProvider(branchId));
    final deptsAsync = ref.watch(_dashboardDepartmentsProvider(branchId));
    final eventsAsync = ref.watch(_dashboardEventsProvider(branchId));
    final correspondenceAsync = ref.watch(_dashboardCorrespondenceProvider(branchId));

    final totalMembers = membersAsync.valueOrNull?.length ?? 0;
    final totalDepts = deptsAsync.valueOrNull?.length ?? 0;
    final totalEvents = eventsAsync.valueOrNull?.length ?? 0;
    final totalCorr = correspondenceAsync.valueOrNull?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleHeader(
            user: user,
            title: 'Secretariat Operations & Administration',
            roleName: 'Secretary',
            roleColor: CmsTheme.info,
          ),
          const SizedBox(height: 24),

          // ── Secretary KPI Cards ───────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Registered Members',
                value: '$totalMembers',
                subtitle: 'Church directory & rosters',
                icon: Icons.people_outline,
                color: CmsTheme.accent,
                onTap: () => context.go(AppRoutes.members),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Ministry Departments',
                value: '$totalDepts',
                subtitle: 'Active groups & unit leaders',
                icon: Icons.groups_outlined,
                color: CmsTheme.info,
                onTap: () => context.go(AppRoutes.departments),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Scheduled Events',
                value: '$totalEvents',
                subtitle: 'Upcoming services & programs',
                icon: Icons.calendar_today_outlined,
                color: CmsTheme.success,
                onTap: () => context.go(AppRoutes.events),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Correspondence Logs',
                value: '$totalCorr',
                subtitle: 'Incoming & outgoing letters',
                icon: Icons.mail_outline,
                color: CmsTheme.warning,
                onTap: () => context.go(AppRoutes.correspondence),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Secretariat Quick Hub & Celebrations ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member Administration & Credentials
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Member & Department Administration', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('As Church Secretary, you have sole authority to manage member profiles and ministry groups.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Add New Member',
                              desc: 'Register a new church member into the CMS directory.',
                              icon: Icons.person_add_outlined,
                              color: CmsTheme.accent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberFormScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Import CSV Roster',
                              desc: 'Batch import member records from CSV file.',
                              icon: Icons.upload_outlined,
                              color: CmsTheme.info,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberImportScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Create Department',
                              desc: 'Add new ministry group or sub-unit.',
                              icon: Icons.add_business_outlined,
                              color: CmsTheme.success,
                              onTap: () => context.go(AppRoutes.departments),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: CmsTheme.border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.file_copy_outlined, size: 18, color: CmsTheme.warning),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Financial Documentation (Read-Only Records)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          ),
                          CmsButton(
                            label: 'Open Docs',
                            icon: Icons.folder_open_outlined,
                            variant: CmsButtonVariant.secondary,
                            compact: true,
                            onPressed: () => context.go(AppRoutes.financialDocs),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Celebrations & Attendance Shortcuts
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const _WeeklyCelebrationsCard(),
                    const SizedBox(height: 16),
                    CmsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Attendance Log Shortcut', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Record headcounts and demographic breakdown for recent services.', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 12),
                          CmsButton(
                            label: 'Log Service Attendance',
                            icon: Icons.how_to_reg_outlined,
                            compact: true,
                            onPressed: () => context.go(AppRoutes.attendance),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _SecretaryQuickActionBar(user: user),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💰 3. FINANCE DEPT DASHBOARD (Financial Operations & Cash Flow)
// ─────────────────────────────────────────────────────────────────────────────

class _FinanceDeptDashboard extends ConsumerWidget {
  const _FinanceDeptDashboard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);

    final incomeAsync = ref.watch(_dashboardIncomeProvider(branchId));
    final givingAsync = ref.watch(_dashboardGivingProvider(branchId));
    final expendituresAsync = ref.watch(_dashboardExpendituresProvider(branchId));
    final notificationsAsync = ref.watch(_dashboardNotificationsProvider((branchId, user.uid)));

    final totalGenInc = incomeAsync.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final totalGiv = givingAsync.valueOrNull?.fold<double>(0, (s, g) => s + g.amount) ?? 0;
    final totalRevenue = totalGenInc + totalGiv;

    final totalApprovedExp = expendituresAsync.valueOrNull?.fold<double>(0, (s, e) => s + e.approvedAmount) ?? 0;
    final totalDisbursed = expendituresAsync.valueOrNull?.fold<double>(0, (s, e) => s + e.totalDisbursed) ?? 0;
    final unreadNotifs = notificationsAsync.valueOrNull?.where((n) => !n.read).length ?? 0;

    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleHeader(
            user: user,
            title: 'Financial Operations & Disbursement Ledger',
            roleName: 'Finance Dept',
            roleColor: CmsTheme.success,
          ),
          const SizedBox(height: 20),

          // ── 1. Top Quick Action Card ──────────────────────────────────────
          CmsCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: CmsTheme.success, size: 20),
                const SizedBox(width: 10),
                const Text('Quick Actions:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      CmsButton(
                        label: 'Finance Analytics',
                        icon: Icons.dashboard_customize_outlined,
                        compact: true,
                        onPressed: () => context.go(AppRoutes.financeDashboard),
                      ),
                      CmsButton(
                        label: 'Record Revenue',
                        icon: Icons.monetization_on_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.income),
                      ),
                      CmsButton(
                        label: 'Record Giving',
                        icon: Icons.volunteer_activism_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.giving),
                      ),
                      CmsButton(
                        label: 'Expenditure Request',
                        icon: Icons.receipt_long_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.expenditures),
                      ),
                      CmsButton(
                        label: 'Disbursements',
                        icon: Icons.payments_outlined,
                        compact: true,
                        variant: CmsButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.disbursements),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 2. Finance KPI Summary Row ────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Total Revenue (Inflows)',
                value: currencyFmt.format(totalRevenue),
                subtitle: 'Tithes, offerings, pledges, & revenue',
                icon: Icons.trending_up,
                color: CmsTheme.success,
                onTap: () => context.go(AppRoutes.income),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Approved Expenditures',
                value: currencyFmt.format(totalApprovedExp),
                subtitle: 'Authorized by Lead Pastor',
                icon: Icons.receipt_long_outlined,
                color: CmsTheme.accent,
                onTap: () => context.go(AppRoutes.expenditures),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Disbursement Progress',
                value: currencyFmt.format(totalDisbursed),
                subtitle: 'Remaining: ${currencyFmt.format(totalApprovedExp - totalDisbursed)}',
                icon: Icons.payments_outlined,
                color: CmsTheme.warning,
                onTap: () => context.go(AppRoutes.disbursements),
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: 'Pastor Alerts & Diffs',
                value: '$unreadNotifs unread',
                subtitle: 'Notifications & change diffs',
                icon: Icons.notifications_outlined,
                color: unreadNotifs > 0 ? CmsTheme.danger : CmsTheme.textMuted,
                onTap: () => context.go(AppRoutes.financeNotifications),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 3. Chart Insights & Income/Expenditure Trends Overview ───────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Income vs Expenditure Trend Bar Chart
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart, color: CmsTheme.success, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Income vs. Expenditure Trend Overview', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                Text('Monthly revenue inflows vs approved expenditure commitments', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeDashboard),
                            child: const Text('View Full Analytics →', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 190,
                        child: _PastorFinancialTrendChart(
                          income: incomeAsync.valueOrNull ?? [],
                          giving: givingAsync.valueOrNull ?? [],
                          expenditures: expendituresAsync.valueOrNull ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Revenue Distribution Donut Chart Overview
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pie_chart_outline, color: CmsTheme.accent, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Revenue Distribution by Source', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                Text('Breakdown across tithes, offerings, pledges, and general income', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeDashboard),
                            child: const Text('Details →', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 190,
                        child: _FinanceRevenueDonutMiniChart(
                          income: incomeAsync.valueOrNull ?? [],
                          giving: givingAsync.valueOrNull ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 4. Operations Hub & Pastor Alerts Row ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inflow & Budget Action Hub
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Financial Operations & Submission Hub', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeDashboard),
                            child: const Text('Open Analytics Overview →', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Record Income',
                              desc: 'Log cash, transfer, cheque, or in-kind revenues.',
                              icon: Icons.monetization_on_outlined,
                              color: CmsTheme.success,
                              onTap: () => context.go(AppRoutes.income),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Record Giving',
                              desc: 'Log member tithes, offerings, or pledges.',
                              icon: Icons.volunteer_activism_outlined,
                              color: CmsTheme.accent,
                              onTap: () => context.go(AppRoutes.giving),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AdminActionTile(
                              title: 'Expenditure Request',
                              desc: 'Submit fund request for pastor approval.',
                              icon: Icons.receipt_long_outlined,
                              color: CmsTheme.warning,
                              onTap: () => context.go(AppRoutes.expenditures),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Recent Notifications / Diffs
              Expanded(
                flex: 2,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Pastor Approval Alerts', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.financeNotifications),
                            child: const Text('View All', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (notificationsAsync.valueOrNull?.isEmpty ?? true)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('No new alerts from pastor', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (notificationsAsync.valueOrNull ?? []).take(3).length,
                          separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 12),
                          itemBuilder: (_, i) {
                            final n = notificationsAsync.valueOrNull![i];
                            return Text(n.message, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary));
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildRoleHeader({
  required dynamic user,
  required String title,
  required String roleName,
  required Color roleColor,
}) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user.displayName ?? user.email.split('@').first}',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: CmsTheme.textSecondary)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: roleColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(roleName, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: roleColor)),
          ],
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CmsTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CmsTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                    Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CmsTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _PastorQuickActionBar extends StatelessWidget {
  const _PastorQuickActionBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CmsButton(
          label: 'Approval Queue',
          icon: Icons.approval_outlined,
          onPressed: () => context.go(AppRoutes.approvalQueue),
        ),
        CmsButton(
          label: 'Finance Overview',
          icon: Icons.dashboard_customize_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.financeDashboard),
        ),
        CmsButton(
          label: 'Announcements',
          icon: Icons.campaign_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.announcements),
        ),
        CmsButton(
          label: 'Audit Log',
          icon: Icons.history_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.auditLog),
        ),
      ],
    );
  }
}

class _SecretaryQuickActionBar extends StatelessWidget {
  const _SecretaryQuickActionBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CmsButton(
          label: 'Members Directory',
          icon: Icons.people_outline,
          onPressed: () => context.go(AppRoutes.members),
        ),
        CmsButton(
          label: 'Departments & Units',
          icon: Icons.groups_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.departments),
        ),
        CmsButton(
          label: 'Log Service Attendance',
          icon: Icons.how_to_reg_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.attendance),
        ),
        CmsButton(
          label: 'Correspondence',
          icon: Icons.mail_outline,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.correspondence),
        ),
      ],
    );
  }
}

class _FinanceQuickActionBar extends StatelessWidget {
  const _FinanceQuickActionBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CmsButton(
          label: 'Finance Analytics',
          icon: Icons.dashboard_customize_outlined,
          onPressed: () => context.go(AppRoutes.financeDashboard),
        ),
        CmsButton(
          label: 'Record Revenue',
          icon: Icons.monetization_on_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.income),
        ),
        CmsButton(
          label: 'Record Giving',
          icon: Icons.volunteer_activism_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.giving),
        ),
        CmsButton(
          label: 'Disbursements Ledger',
          icon: Icons.payments_outlined,
          variant: CmsButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.disbursements),
        ),
      ],
    );
  }
}

class _WeeklyCelebrationsCard extends ConsumerWidget {
  const _WeeklyCelebrationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final membersAsync = ref.watch(_dashboardMembersProvider(branchId));

    return CmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_outlined, size: 18, color: CmsTheme.warning),
              const SizedBox(width: 8),
              const Text('Weekly Celebrations & Member Care', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              final now = DateTime.now();
              final endOfWeek = now.add(const Duration(days: 7));

              final upcoming = members.where((m) {
                if (m.dob == null) return false;
                final dob = m.dob!;
                final bdayThisYear = DateTime(now.year, dob.month, dob.day);
                return bdayThisYear.isAfter(now.subtract(const Duration(days: 1))) &&
                    bdayThisYear.isBefore(endOfWeek);
              }).take(4).toList();

              if (upcoming.isEmpty) {
                return const Text('No birthdays or anniversaries this week.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted));
              }

              return Column(
                children: upcoming.map((m) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Text('${m.firstName} ${m.lastName}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary)),
                      const Spacer(),
                      Text('Birthday: ${m.dob!.day}/${m.dob!.month}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.warning)),
                    ],
                  ),
                )).toList(),
              );

            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pastor Visual Trend Charts
// ─────────────────────────────────────────────────────────────────────────────

class _PastorFinancialTrendChart extends StatelessWidget {
  const _PastorFinancialTrendChart({
    required this.income,
    required this.giving,
    required this.expenditures,
  });

  final List<IncomeModel> income;
  final List<GivingModel> giving;
  final List<ExpenditureModel> expenditures;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final compactFmt = NumberFormat.compact();

    final List<BarChartGroupData> groups = [];
    double maxY = 1000;

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final incTotal = income
              .where((x) => x.date.year == m.year && x.date.month == m.month)
              .fold<double>(0, (s, x) => s + x.amount) +
          giving
              .where((x) => x.date.year == m.year && x.date.month == m.month)
              .fold<double>(0, (s, x) => s + x.amount);

      final expTotal = expenditures
          .where((x) => x.date.year == m.year && x.date.month == m.month)
          .fold<double>(0, (s, x) => s + x.approvedAmount);

      if (incTotal > maxY) maxY = incTotal;
      if (expTotal > maxY) maxY = expTotal;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: incTotal, color: CmsTheme.success, width: 10, borderRadius: BorderRadius.circular(3)),
            BarChartRodData(toY: expTotal, color: CmsTheme.accent, width: 10, borderRadius: BorderRadius.circular(3)),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 3),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text('₦${compactFmt.format(v)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, _) {
                if (i.toInt() >= 0 && i.toInt() < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('MMM').format(months[i.toInt()]), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }
}

class _PastorAttendanceTrendChart extends StatelessWidget {
  const _PastorAttendanceTrendChart({required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No service headcount records logged yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
      );
    }

    final sortedEvents = List<EventModel>.from(events)..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final recent = sortedEvents.take(8).toList();

    double maxHeadcount = 10;
    final spots = <FlSpot>[];

    for (int i = 0; i < recent.length; i++) {
      final hc = recent[i].headcount.toDouble();
      if (hc > maxHeadcount) maxHeadcount = hc;
      spots.add(FlSpot(i.toDouble(), hc));
    }

    return LineChart(
      LineChartData(
        maxY: maxHeadcount * 1.2,
        minY: 0,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxHeadcount / 3),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, _) {
                final idx = i.toInt();
                if (idx >= 0 && idx < recent.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('d/M').format(recent[idx].dateTime), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: CmsTheme.info,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: CmsTheme.info.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRevenueDonutMiniChart extends StatelessWidget {
  const _FinanceRevenueDonutMiniChart({
    required this.income,
    required this.giving,
  });

  final List<IncomeModel> income;
  final List<GivingModel> giving;

  @override
  Widget build(BuildContext context) {
    double tithes = 0;
    double offerings = 0;
    double pledges = 0;
    double generalInc = 0;

    for (final g in giving) {
      final type = g.type.toLowerCase();
      if (type.contains('tithe')) tithes += g.amount;
      else if (type.contains('offering')) offerings += g.amount;
      else if (type.contains('pledge')) pledges += g.amount;
      else offerings += g.amount;
    }


    for (final inc in income) {
      generalInc += inc.amount;
    }

    final total = tithes + offerings + pledges + generalInc;

    if (total == 0) {
      return const Center(
        child: Text('No revenue entries recorded yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                if (tithes > 0)
                  PieChartSectionData(value: tithes, color: CmsTheme.success, title: '${(tithes / total * 100).toStringAsFixed(0)}%', radius: 24, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                if (offerings > 0)
                  PieChartSectionData(value: offerings, color: CmsTheme.accent, title: '${(offerings / total * 100).toStringAsFixed(0)}%', radius: 24, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                if (pledges > 0)
                  PieChartSectionData(value: pledges, color: CmsTheme.warning, title: '${(pledges / total * 100).toStringAsFixed(0)}%', radius: 24, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                if (generalInc > 0)
                  PieChartSectionData(value: generalInc, color: CmsTheme.info, title: '${(generalInc / total * 100).toStringAsFixed(0)}%', radius: 24, titleStyle: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Tithes', CmsTheme.success),
              const SizedBox(height: 6),
              _buildLegendItem('Offerings', CmsTheme.accent),
              const SizedBox(height: 6),
              _buildLegendItem('Pledges', CmsTheme.warning),
              const SizedBox(height: 6),
              _buildLegendItem('General', CmsTheme.info),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
      ],
    );
  }
}


