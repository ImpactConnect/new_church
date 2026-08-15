import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/features/auth/screens/login_screen.dart';
import 'package:cms/src/features/dashboard/screens/dashboard_screen.dart';
import 'package:cms/src/features/members/screens/member_list_screen.dart';
import 'package:cms/src/features/departments/screens/department_list_screen.dart';
import 'package:cms/src/features/roles/screens/role_list_screen.dart';
import 'package:cms/src/features/audit/screens/audit_log_screen.dart';
import 'package:cms/src/features/branches/screens/branch_settings_screen.dart';
import 'package:cms/src/features/events/screens/event_list_screen.dart';
import 'package:cms/src/features/events/screens/attendance_report_screen.dart';
import 'package:cms/src/features/announcements/screens/announcement_list_screen.dart';
import 'package:cms/src/features/correspondence/screens/correspondence_screen.dart';
import 'package:cms/src/features/approval/screens/approval_queue_screen.dart';
import 'package:cms/src/features/finance/screens/income_list_screen.dart';
import 'package:cms/src/features/finance/screens/giving_list_screen.dart';
import 'package:cms/src/features/finance/screens/budget_list_screen.dart';
import 'package:cms/src/features/finance/screens/expenditure_list_screen.dart';
import 'package:cms/src/features/finance/screens/disbursement_list_screen.dart';
import 'package:cms/src/features/assets/screens/asset_list_screen.dart';
import 'package:cms/src/features/reports/screens/reports_screen.dart';
import 'package:cms/src/features/shell/screens/app_shell.dart';

// Route paths
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const members = '/members';
  static const attendance = '/attendance';
  static const departments = '/departments';
  static const events = '/events';
  static const announcements = '/announcements';
  static const correspondence = '/correspondence';
  static const income = '/income';
  static const giving = '/giving';
  static const budgets = '/budgets';
  static const expenditures = '/expenditures';
  static const disbursements = '/disbursements';
  static const assets = '/assets';
  static const reports = '/reports';
  static const approvalQueue = '/approval-queue';
  static const auditLog = '/audit-log';
  static const roles = '/roles';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(cmsUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (isLoading) return null; // Let the splash handle this
      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;
      if (isLoggedIn && isLoginRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.approvalQueue,
            builder: (context, state) => const ApprovalQueueScreen(),
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.manageMembers, AppPermission.viewNonFinancialReports],
              child: MemberListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.departments,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.manageDepartments, AppPermission.viewNonFinancialReports],
              child: DepartmentListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.events,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.manageEvents,
              child: EventListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.announcements,
            builder: (context, state) => const AnnouncementListScreen(),
          ),
          GoRoute(
            path: AppRoutes.correspondence,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.logCorrespondence,
              child: CorrespondenceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.income,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.recordIncome, AppPermission.viewFinancialReports],
              child: IncomeListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.giving,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.recordIncome, AppPermission.viewFinancialReports],
              child: GivingListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.budgets,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.createBudgetRequest, AppPermission.approveBudget, AppPermission.viewFinancialReports],
              child: BudgetListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.expenditures,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.createExpenditureRequest, AppPermission.approveExpenditure, AppPermission.viewFinancialReports],
              child: ExpenditureListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.disbursements,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.recordDisbursement, AppPermission.viewFinancialReports],
              child: DisbursementListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.assets,
            builder: (context, state) => const AssetListScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.roles,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.manageRoles,
              child: RoleListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.auditLog,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.manageRoles,
              child: AuditLogScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const BranchSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.recordAttendance, AppPermission.viewNonFinancialReports, AppPermission.manageEvents],
              child: AttendanceReportScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// A widget that checks if the current user has [required] or [anyOf] permissions.
/// Renders [child] if authorized; a 403 message otherwise.
class _PermissionGate extends ConsumerWidget {
  const _PermissionGate({this.required, this.anyOf, required this.child});
  final String? required;
  final List<String>? anyOf;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(cmsUserProvider).valueOrNull;
    bool allowed = false;
    if (user != null) {
      if (required != null && user.can(required!)) allowed = true;
      if (anyOf != null && anyOf!.any((p) => user.can(p))) allowed = true;
    }
    if (!allowed) {
      return const Scaffold(
        body: Center(
          child: Text(
            '403 — You do not have permission to access this section.',
          ),
        ),
      );
    }
    return child;
  }
}
