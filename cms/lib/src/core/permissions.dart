// Core permission catalog — atomic permissions that are stored in role documents
// in Firestore and checked both client-side (UX) and server-side (Security Rules).
class AppPermission {
  const AppPermission._();

  static const String manageMembers = 'manageMembers';
  static const String manageRoles = 'manageRoles';
  static const String recordAttendance = 'recordAttendance';
  static const String manageEvents = 'manageEvents';
  static const String manageDepartments = 'manageDepartments';
  static const String createAnnouncement = 'createAnnouncement';
  static const String approveAnnouncement = 'approveAnnouncement';
  static const String logCorrespondence = 'logCorrespondence';
  static const String recordIncome = 'recordIncome';
  static const String createBudgetRequest = 'createBudgetRequest';
  static const String approveBudget = 'approveBudget';
  static const String createExpenditureRequest = 'createExpenditureRequest';
  static const String approveExpenditure = 'approveExpenditure';
  static const String recordDisbursement = 'recordDisbursement';
  static const String manageAssetPhysical = 'manageAssetPhysical';
  static const String manageAssetFinancial = 'manageAssetFinancial';
  static const String viewFinancialReports = 'viewFinancialReports';
  static const String viewNonFinancialReports = 'viewNonFinancialReports';
  static const String sendNotifications = 'sendNotifications';
  // Branch Pastor specific
  static const String isBranchPastor = 'isBranchPastor';
  static const String sendIncomeReport = 'sendIncomeReport';
  static const String viewBranchReports = 'viewBranchReports';
  // Sub-Group & Cell Operations
  static const String manageSubGroups = 'manageSubGroups';
  static const String recordSubGroupAttendance = 'recordSubGroupAttendance';
  static const String recordSubGroupIncome = 'recordSubGroupIncome';
  static const String viewSubGroupReports = 'viewSubGroupReports';

  static const List<String> all = [
    manageMembers,
    manageRoles,
    recordAttendance,
    manageEvents,
    manageDepartments,
    manageSubGroups,
    recordSubGroupAttendance,
    recordSubGroupIncome,
    viewSubGroupReports,
    createAnnouncement,
    approveAnnouncement,
    logCorrespondence,
    recordIncome,
    createBudgetRequest,
    approveBudget,
    createExpenditureRequest,
    approveExpenditure,
    recordDisbursement,
    manageAssetPhysical,
    manageAssetFinancial,
    viewFinancialReports,
    viewNonFinancialReports,
    sendNotifications,
    isBranchPastor,
    sendIncomeReport,
    viewBranchReports,
  ];
}

// v1 seeded roles — document IDs in Firestore
class AppRole {
  const AppRole._();

  static const String leadPastor = 'leadPastor';
  static const String secretary = 'secretary';
  static const String financeDept = 'financeDept';
  static const String branchPastor = 'branchPastor';

  /// Default permission sets used to seed Firestore on first setup.
  static const Map<String, List<String>> defaultPermissions = {
    leadPastor: [
      AppPermission.manageRoles,
      AppPermission.manageSubGroups,
      AppPermission.recordSubGroupAttendance,
      AppPermission.recordSubGroupIncome,
      AppPermission.viewSubGroupReports,
      AppPermission.recordAttendance,
      AppPermission.manageEvents,
      AppPermission.createAnnouncement,
      AppPermission.approveAnnouncement,
      AppPermission.logCorrespondence,
      AppPermission.recordIncome,
      AppPermission.createBudgetRequest,
      AppPermission.approveBudget,
      AppPermission.createExpenditureRequest,
      AppPermission.approveExpenditure,
      AppPermission.recordDisbursement,
      AppPermission.manageAssetPhysical,
      AppPermission.manageAssetFinancial,
      AppPermission.viewFinancialReports,
      AppPermission.viewNonFinancialReports,
      AppPermission.sendNotifications,
    ],

    secretary: [
      AppPermission.manageMembers,
      AppPermission.manageSubGroups,
      AppPermission.viewSubGroupReports,
      AppPermission.recordSubGroupAttendance,
      AppPermission.recordAttendance,
      AppPermission.manageEvents,
      AppPermission.manageDepartments,
      AppPermission.createAnnouncement,
      AppPermission.logCorrespondence,
      AppPermission.manageAssetPhysical,
      AppPermission.viewNonFinancialReports,
    ],

    financeDept: [
      AppPermission.recordIncome,
      AppPermission.createBudgetRequest,
      AppPermission.createExpenditureRequest,
      AppPermission.recordDisbursement,
      AppPermission.manageAssetFinancial,
      AppPermission.viewFinancialReports,
    ],

    // Branch Pastor: sole operator of a branch church — combines secretary + finance + reporting
    branchPastor: [
      AppPermission.isBranchPastor,       // sentinel flag — used for UI routing
      AppPermission.manageMembers,         // add/edit branch members (auto-syncs to main list)
      AppPermission.recordAttendance,      // record attendance per service
      AppPermission.manageEvents,          // log branch services/events
      AppPermission.recordIncome,          // log branch income + giving
      AppPermission.createBudgetRequest,   // submit budget requests to HQ
      AppPermission.createExpenditureRequest, // submit expenditure requests to HQ
      AppPermission.sendIncomeReport,      // submit income remittance to HQ finance dept
      AppPermission.viewBranchReports,     // view approved budgets/expenditures from Lead Pastor
    ],
  };
}
