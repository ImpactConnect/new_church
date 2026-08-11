import 'package:cms/src/features/finance/models/budget_model.dart';

/// Abstract interface for all financial data access.
abstract class FinanceRepository {
  // ── Income ──────────────────────────────────────────────────────────────────
  Future<void> recordIncome(String branchId, IncomeModel income);
  Stream<List<IncomeModel>> watchIncome(String branchId);

  // ── Giving ──────────────────────────────────────────────────────────────────
  Future<void> recordGiving(String branchId, GivingModel giving);
  Stream<List<GivingModel>> watchGiving(String branchId);

  // ── Budget ───────────────────────────────────────────────────────────────────
  Future<void> createBudgetRequest(String branchId, BudgetModel budget);
  Stream<List<BudgetModel>> watchBudgets(String branchId, {String? status});
  Future<void> approveBudget(String branchId, String budgetId, String approvedBy, String approvedByName);
  Future<void> rejectBudget(String branchId, String budgetId, String reason);
  Future<void> updateBudgetStatus(
    String branchId,
    String budgetId,
    String status, {
    double? approvedAmount,
    String? approvedBy,
    List<Map<String, dynamic>>? changesSummary,
  });

  // ── Expenditure Request ──────────────────────────────────────────────────────
  Future<void> createExpenditureRequest(
    String branchId,
    ExpenditureRequestModel request,
  );
  Stream<List<ExpenditureRequestModel>> watchExpenditureRequests(
    String branchId, {
    String? status,
  });
  Future<void> approveExpenditure(String branchId, String requestId, String approvedBy, String approvedByName);
  Future<void> rejectExpenditure(String branchId, String requestId, String reason);

  // ── Approved Expenditure Ledger ──────────────────────────────────────────────
  Stream<List<ExpenditureModel>> watchExpenditures(String branchId);
  Future<ExpenditureModel?> getExpenditure(
    String branchId,
    String expenditureId,
  );

  // ── Disbursements ─────────────────────────────────────────────────────────────
  Future<void> recordDisbursement(
    String branchId,
    String expenditureId,
    DisbursementModel disbursement,
  );
  Stream<List<DisbursementModel>> watchDisbursements(
    String branchId,
    String expenditureId,
  );
}
