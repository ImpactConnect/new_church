import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/routing/app_router.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/features/sync/services/connectivity_service.dart';
import 'package:cms/src/features/sync/services/sync_engine.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(cmsUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Authentication error')),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return Scaffold(
          backgroundColor: CmsTheme.bg,
          body: Row(
            children: [
              _Sidebar(user: user),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(user: user),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerStatefulWidget {
  const _Sidebar({required this.user});
  final dynamic user;

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = widget.user;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: CmsTheme.sidebar,
        border: Border(right: BorderSide(color: CmsTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Brand
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: CmsTheme.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.church, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Church CMS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CmsTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: CmsTheme.border, height: 1),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    path: AppRoutes.dashboard,
                    current: location,
                  ),
                  if (user.can(AppPermission.approveBudget) ||
                      user.can(AppPermission.approveExpenditure) ||
                      user.can(AppPermission.approveAnnouncement))
                    _NavItem(
                      icon: Icons.inbox_outlined,
                      label: 'Approval Queue',
                      path: AppRoutes.approvalQueue,
                      current: location,
                      badge: true,
                    ),
                  const _SectionLabel('People'),
                  if (user.can(AppPermission.manageMembers))
                    _NavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      path: AppRoutes.members,
                      current: location,
                    ),
                  if (user.can(AppPermission.manageDepartments))
                    _NavItem(
                      icon: Icons.groups_outlined,
                      label: 'Departments',
                      path: AppRoutes.departments,
                      current: location,
                    ),
                  if (user.can(AppPermission.recordAttendance))
                    _NavItem(
                      icon: Icons.how_to_reg_outlined,
                      label: 'Attendance',
                      path: AppRoutes.attendance,
                      current: location,
                    ),
                  const _SectionLabel('Communication'),
                  if (user.can(AppPermission.manageEvents))
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Events',
                      path: AppRoutes.events,
                      current: location,
                    ),
                  if (user.can(AppPermission.createAnnouncement) ||
                      user.can(AppPermission.approveAnnouncement))
                    _NavItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      path: AppRoutes.announcements,
                      current: location,
                    ),
                  if (user.can(AppPermission.logCorrespondence))
                    _NavItem(
                      icon: Icons.mail_outline,
                      label: 'Correspondence',
                      path: AppRoutes.correspondence,
                      current: location,
                    ),
                  const _SectionLabel('Finance'),
                  if (user.can(AppPermission.recordIncome))
                    _NavItem(
                      icon: Icons.trending_up_outlined,
                      label: 'Income',
                      path: AppRoutes.income,
                      current: location,
                    ),
                  if (user.can(AppPermission.recordIncome))
                    _NavItem(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Giving',
                      path: AppRoutes.giving,
                      current: location,
                    ),
                  if (user.can(AppPermission.createBudgetRequest) ||
                      user.can(AppPermission.approveBudget))
                    _NavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Budgets',
                      path: AppRoutes.budgets,
                      current: location,
                    ),
                  if (user.can(AppPermission.createExpenditureRequest) ||
                      user.can(AppPermission.approveExpenditure))
                    _NavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Expenditures',
                      path: AppRoutes.expenditures,
                      current: location,
                    ),
                  if (user.can(AppPermission.recordDisbursement))
                    _NavItem(
                      icon: Icons.payments_outlined,
                      label: 'Disbursements',
                      path: AppRoutes.disbursements,
                      current: location,
                    ),
                  const _SectionLabel('Admin'),
                  if (user.can(AppPermission.manageAssetPhysical) ||
                      user.can(AppPermission.manageAssetFinancial))
                    _NavItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Assets',
                      path: AppRoutes.assets,
                      current: location,
                    ),
                  if (user.can(AppPermission.viewFinancialReports) ||
                      user.can(AppPermission.viewNonFinancialReports))
                    _NavItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports',
                      path: AppRoutes.reports,
                      current: location,
                    ),
                  if (user.can(AppPermission.manageRoles))
                    _NavItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Roles',
                      path: AppRoutes.roles,
                      current: location,
                    ),
                  if (user.can(AppPermission.manageRoles))
                    _NavItem(
                      icon: Icons.history_outlined,
                      label: 'Audit Log',
                      path: AppRoutes.auditLog,
                      current: location,
                    ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    path: AppRoutes.settings,
                    current: location,
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: CmsTheme.border, height: 1),
          // Role badge + user info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                  child: Text(
                    (user.displayName?.isNotEmpty == true
                            ? user.displayName![0]
                            : user.email[0])
                        .toUpperCase(),
                    style: const TextStyle(
                      color: CmsTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _roleLabel(user.roleId),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
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

  String _roleLabel(String roleId) {
    return switch (roleId) {
      'leadPastor' => 'Lead Pastor',
      'secretary' => 'Secretary',
      'financeDept' => 'Finance Dept',
      _ => roleId,
    };
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.current,
    this.badge = false,
  });
  final IconData icon;
  final String label;
  final String path;
  final String current;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final isActive = current == path;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? CmsTheme.accent.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? CmsTheme.accent : CmsTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? CmsTheme.accent
                          : CmsTheme.textSecondary,
                    ),
                  ),
                ),
                if (badge)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CmsTheme.warning,
                      shape: BoxShape.circle,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CmsTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: CmsTheme.sidebar,
        border: Border(bottom: BorderSide(color: CmsTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            _pageTitle(GoRouterState.of(context).matchedLocation),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CmsTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Sync status indicator
          Consumer(
            builder: (context, ref, _) {
              final syncState = ref.watch(syncEngineProvider);
              final isOnline = syncState.networkState == NetworkState.online;
              final isSyncing = syncState.isSyncing;
              final pending = syncState.pendingCount;

              final badgeColor = isSyncing
                  ? CmsTheme.warning
                  : isOnline
                      ? CmsTheme.success
                      : CmsTheme.danger;

              final label = isSyncing
                  ? 'Syncing ($pending)'
                  : isOnline
                      ? (pending > 0 ? '$pending Pending' : 'Online')
                      : 'Offline';

              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSyncing)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: CmsTheme.warning),
                      )
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Notification bell
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: CmsTheme.textSecondary,
              size: 20,
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 4),
          // Sign out
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: CmsTheme.textSecondary,
              size: 20,
            ),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }

  String _pageTitle(String location) {
    return switch (location) {
      AppRoutes.dashboard => 'Dashboard',
      AppRoutes.approvalQueue => 'Approval Queue',
      AppRoutes.members => 'Members',
      AppRoutes.departments => 'Departments',
      AppRoutes.attendance => 'Attendance',
      AppRoutes.events => 'Events',
      AppRoutes.announcements => 'Announcements',
      AppRoutes.correspondence => 'Correspondence',
      AppRoutes.income => 'Income',
      AppRoutes.giving => 'Giving Records',
      AppRoutes.budgets => 'Budgets',
      AppRoutes.expenditures => 'Expenditures',
      AppRoutes.disbursements => 'Disbursements',
      AppRoutes.assets => 'Assets & Inventory',
      AppRoutes.reports => 'Reports & Analytics',
      AppRoutes.roles => 'Roles & Permissions',
      AppRoutes.auditLog => 'Audit Log',
      AppRoutes.settings => 'Branch Settings',
      _ => 'Church CMS',
    };
  }
}
