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

  static const List<String> all = [
    manageMembers,
    manageRoles,
    recordAttendance,
    manageEvents,
    manageDepartments,
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
  ];
}

// v1 seeded roles — document IDs in Firestore
class AppRole {
  const AppRole._();

  static const String leadPastor = 'leadPastor';
  static const String secretary = 'secretary';
  static const String financeDept = 'financeDept';

  /// Default permission sets used to seed Firestore on first setup.
  static const Map<String, List<String>> defaultPermissions = {
    leadPastor: [
      AppPermission.manageMembers,
      AppPermission.manageRoles,
      AppPermission.manageEvents,
      AppPermission.manageDepartments,
      AppPermission.approveAnnouncement,
      AppPermission.approveBudget,
      AppPermission.approveExpenditure,
      AppPermission.viewFinancialReports,
      AppPermission.viewNonFinancialReports,
      AppPermission.sendNotifications,
    ],
    secretary: [
      AppPermission.manageMembers,
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
  };
}
