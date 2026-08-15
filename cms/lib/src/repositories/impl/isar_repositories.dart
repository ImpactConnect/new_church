import 'package:cms/src/features/auth/models/cms_user_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/repositories/auth_repository.dart';
import 'package:cms/src/repositories/finance_repository.dart';
import 'package:cms/src/repositories/member_repository.dart';

/// Desktop stub implementations (Phase 0-4 proxying to Firebase, Phase 5 full Isar offline).
class IsarAuthRepository implements AuthRepository {
  IsarAuthRepository({required AuthRepository delegate}) : _delegate = delegate;
  final AuthRepository _delegate;

  @override
  Stream<CmsUserModel?> get authStateChanges => _delegate.authStateChanges;
  @override
  CmsUserModel? get currentUser => _delegate.currentUser;
  @override
  Future<CmsUserModel> signInWithEmailAndPassword(String email, String password) =>
      _delegate.signInWithEmailAndPassword(email, password);
  @override
  Future<void> signOut() => _delegate.signOut();
  @override
  Future<void> refreshToken() => _delegate.refreshToken();
}

class IsarMemberRepository implements MemberRepository {
  IsarMemberRepository({required MemberRepository delegate})
    : _delegate = delegate;
  final MemberRepository _delegate;

  @override
  Stream<List<MemberModel>> watchMembers(String branchId) =>
      _delegate.watchMembers(branchId);
  @override
  Future<MemberModel?> getMember(String branchId, String memberId) =>
      _delegate.getMember(branchId, memberId);
  @override
  Future<void> saveMember(String branchId, MemberModel member) =>
      _delegate.saveMember(branchId, member);
  @override
  Future<void> updateMemberStatus(
    String branchId,
    String memberId,
    String status,
  ) => _delegate.updateMemberStatus(branchId, memberId, status);
  @override
  Future<void> deleteMember(String branchId, String memberId) =>
      _delegate.deleteMember(branchId, memberId);
  @override
  Future<void> importMembers(
    String branchId,
    List<MemberModel> members,
    String importBatchId,
  ) => _delegate.importMembers(branchId, members, importBatchId);
}

class IsarFinanceRepository implements FinanceRepository {
  IsarFinanceRepository({required FinanceRepository delegate})
    : _delegate = delegate;
  final FinanceRepository _delegate;

  @override
  Future<void> recordIncome(String branchId, IncomeModel income) => _delegate.recordIncome(branchId, income);
  @override
  Stream<List<IncomeModel>> watchIncome(String branchId) => _delegate.watchIncome(branchId);
  @override
  Future<void> recordGiving(String branchId, GivingModel giving) => _delegate.recordGiving(branchId, giving);
  @override
  Stream<List<GivingModel>> watchGiving(String branchId) => _delegate.watchGiving(branchId);
  @override
  Future<void> createBudgetRequest(String branchId, BudgetModel budget) => _delegate.createBudgetRequest(branchId, budget);
  @override
  Stream<List<BudgetModel>> watchBudgets(String branchId, {String? status}) => _delegate.watchBudgets(branchId, status: status);
  @override
  Future<void> approveBudget(String branchId, String budgetId, String approvedBy, String approvedByName) =>
      _delegate.approveBudget(branchId, budgetId, approvedBy, approvedByName);
  @override
  Future<void> rejectBudget(String branchId, String budgetId, String reason) =>
      _delegate.rejectBudget(branchId, budgetId, reason);
  @override
  Future<void> updateBudgetStatus(
    String branchId,
    String budgetId,
    String status, {
    double? approvedAmount,
    String? approvedBy,
    List<Map<String, dynamic>>? changesSummary,
  }) => _delegate.updateBudgetStatus(
    branchId, budgetId, status,
    approvedAmount: approvedAmount,
    approvedBy: approvedBy,
    changesSummary: changesSummary,
  );
  @override
  Future<void> createExpenditureRequest(
    String branchId,
    ExpenditureRequestModel request,
  ) => _delegate.createExpenditureRequest(branchId, request);
  @override
  Stream<List<ExpenditureRequestModel>> watchExpenditureRequests(
    String branchId, {
    String? status,
  }) => _delegate.watchExpenditureRequests(branchId, status: status);
  @override
  Future<void> approveExpenditure(String branchId, String requestId, String approvedBy, String approvedByName) =>
      _delegate.approveExpenditure(branchId, requestId, approvedBy, approvedByName);
  @override
  Future<void> rejectExpenditure(String branchId, String requestId, String reason) =>
      _delegate.rejectExpenditure(branchId, requestId, reason);
  @override
  Stream<List<ExpenditureModel>> watchExpenditures(String branchId) =>
      _delegate.watchExpenditures(branchId);
  @override
  Future<ExpenditureModel?> getExpenditure(String branchId, String expenditureId) =>
      _delegate.getExpenditure(branchId, expenditureId);
  @override
  Future<void> recordDisbursement(
    String branchId,
    String expenditureId,
    DisbursementModel disbursement,
  ) => _delegate.recordDisbursement(branchId, expenditureId, disbursement);
  @override
  Stream<List<DisbursementModel>> watchDisbursements(
    String branchId,
    String expenditureId,
  ) => _delegate.watchDisbursements(branchId, expenditureId);
}
