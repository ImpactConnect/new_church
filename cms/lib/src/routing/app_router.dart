import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/features/auth/screens/login_screen.dart';
import 'package:cms/src/features/dashboard/screens/dashboard_screen.dart';
import 'package:cms/src/features/members/screens/member_list_screen.dart';
import 'package:cms/src/features/departments/screens/department_list_screen.dart';
import 'package:cms/src/features/sub_groups/screens/sub_group_list_screen.dart';
import 'package:cms/src/features/roles/screens/role_list_screen.dart';
import 'package:cms/src/features/audit/screens/audit_log_screen.dart';
import 'package:cms/src/features/branches/screens/branch_settings_screen.dart';
import 'package:cms/src/features/branches/screens/branch_list_screen.dart';
import 'package:cms/src/features/branches/screens/branch_detail_screen.dart';
import 'package:cms/src/features/branches/screens/remittance_screen.dart';
import 'package:cms/src/features/branches/screens/resource_request_screen.dart';
import 'package:cms/src/features/branches/screens/branch_pastor_dashboard_screen.dart';
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
import 'package:cms/src/features/finance/screens/finance_dashboard_screen.dart';
import 'package:cms/src/features/finance/screens/finance_notifications_screen.dart';
import 'package:cms/src/features/finance/screens/secretary_financial_docs_screen.dart';
import 'package:cms/src/features/assets/screens/asset_list_screen.dart';
import 'package:cms/src/features/communication/screens/communication_desk_screen.dart';
import 'package:cms/src/features/reports/screens/reports_screen.dart';
import 'package:cms/src/features/shell/screens/app_shell.dart';


// Route paths
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const members = '/members';
  static const attendance = '/attendance';
  static const departments = '/departments';
  static const subGroups = '/sub-groups';
  static const events = '/events';
  static const announcements = '/announcements';
  static const correspondence = '/correspondence';
  static const financeDashboard = '/finance-dashboard';
  static const income = '/income';
  static const giving = '/giving';
  static const budgets = '/budgets';
  static const expenditures = '/expenditures';
  static const disbursements = '/disbursements';
  static const financeNotifications = '/finance-notifications';
  static const financialDocs = '/financial-docs';
  static const assets = '/assets';
  static const communication = '/communication';
  static const reports = '/reports';
  static const approvalQueue = '/approval-queue';
  static const auditLog = '/audit-log';
  static const roles = '/roles';
  static const branches = '/branches';
  static const branchDetail = '/branches/:branchId';
  static const settings = '/settings';
  // Branch pastor specific routes
  static const remittances = '/remittances';
  static const resourceRequests = '/resource-requests';
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

      if (isLoading) return null;
      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;
      if (isLoggedIn && isLoginRoute) return AppRoutes.dashboard;

      // Branch pastor should not access admin-only routes
      if (user != null && user.can(AppPermission.isBranchPastor)) {
        final adminRoutes = [AppRoutes.branches, AppRoutes.roles, AppRoutes.auditLog, AppRoutes.departments, AppRoutes.announcements, AppRoutes.correspondence, AppRoutes.communication, AppRoutes.disbursements, AppRoutes.assets, AppRoutes.reports];
        if (adminRoutes.contains(state.matchedLocation)) {
          return AppRoutes.dashboard;
        }
      }
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
            builder: (context, state) {
              // Branch Pastor gets their own scoped dashboard
              final user = ref.read(cmsUserProvider).valueOrNull;
              if (user != null && user.can(AppPermission.isBranchPastor)) {
                return const BranchPastorDashboardScreen();
              }
              return const DashboardScreen();
            },
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
            path: AppRoutes.subGroups,
            builder: (context, state) => const SubGroupListScreen(),
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
            path: AppRoutes.financeDashboard,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.createBudgetRequest, AppPermission.createExpenditureRequest,
                      AppPermission.recordIncome, AppPermission.viewFinancialReports],
              child: FinanceDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.financeNotifications,
            builder: (context, state) => const _PermissionGate(
              anyOf: [AppPermission.createBudgetRequest, AppPermission.createExpenditureRequest,
                      AppPermission.recordIncome],
              child: FinanceNotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.financialDocs,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.viewNonFinancialReports,
              child: SecretaryFinancialDocsScreen(),
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
            path: AppRoutes.communication,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.sendCommunication,
              child: CommunicationDeskScreen(),
            ),
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
            path: AppRoutes.roles,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.manageRoles,
              child: RoleListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.branches,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.manageRoles,
              child: BranchListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.branchDetail,
            builder: (context, state) {
              final branchId = state.pathParameters['branchId'] ?? '';
              return _PermissionGate(
                required: AppPermission.manageRoles,
                child: BranchDetailScreen(branchId: branchId),
              );
            },
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
          // Branch pastor specific routes
          GoRoute(
            path: AppRoutes.remittances,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.sendIncomeReport,
              child: RemittanceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.resourceRequests,
            builder: (context, state) => const _PermissionGate(
              required: AppPermission.isBranchPastor,
              child: ResourceRequestScreen(),
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
