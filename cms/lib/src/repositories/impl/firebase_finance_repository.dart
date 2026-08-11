import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/repositories/finance_repository.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:uuid/uuid.dart';

/// Web implementation — direct Firestore calls for all financial data.
class FirebaseFinanceRepository implements FinanceRepository {
  FirebaseFinanceRepository({required FirebaseFirestore firestore})
    : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  DocumentReference _branchDoc(String branchId) =>
      _db.collection('branches').doc(branchId);

  CollectionReference<Map<String, dynamic>> _col(
    String branchId,
    String col,
  ) => _branchDoc(branchId).collection(col)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          );

  // ── Income ──────────────────────────────────────────────────────────────────
  @override
  Future<void> recordIncome(String branchId, IncomeModel income) async {
    final id = income.id.isEmpty ? _uuid.v4() : income.id;
    await _col(branchId, 'income').doc(id).set(income.toFirestore());
  }

  @override
  Stream<List<IncomeModel>> watchIncome(String branchId) =>
      _col(branchId, 'income')
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => IncomeModel.fromFirestore(d.data(), d.id))
                .toList(),
          );

  // ── Giving ──────────────────────────────────────────────────────────────────
  @override
  Future<void> recordGiving(String branchId, GivingModel giving) async {
    final id = giving.id.isEmpty ? _uuid.v4() : giving.id;
    await _col(branchId, 'giving').doc(id).set(giving.toFirestore());
  }

  @override
  Stream<List<GivingModel>> watchGiving(String branchId) =>
      _col(branchId, 'giving')
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => GivingModel.fromFirestore(d.data(), d.id))
                .toList(),
          );

  // ── Budget ───────────────────────────────────────────────────────────────────
  @override
  Future<void> createBudgetRequest(String branchId, BudgetModel budget) async {
    final id = budget.id.isEmpty ? _uuid.v4() : budget.id;
    await _col(branchId, 'budgets').doc(id).set(budget.toFirestore());
  }

  @override
  Stream<List<BudgetModel>> watchBudgets(String branchId, {String? status}) {
    Query<Map<String, dynamic>> query = _col(branchId, 'budgets');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
      (s) => s.docs.map((d) => BudgetModel.fromFirestore(d.data(), d.id)).toList(),
    );
  }

  @override
  Future<void> approveBudget(
    String branchId,
    String budgetId,
    String approvedBy,
    String approvedByName,
  ) async {
    final doc = await _col(branchId, 'budgets').doc(budgetId).get();
    final requested = (doc.data()?['requestedAmount'] as num?)?.toDouble() ?? 0;

    await _col(branchId, 'budgets').doc(budgetId).update({
      'status': 'approved',
      'approvedAmount': requested,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectBudget(String branchId, String budgetId, String reason) async {
    await _col(branchId, 'budgets').doc(budgetId).update({
      'status': 'rejected',
      'rejectionReason': reason,
    });
  }

  @override
  Future<void> updateBudgetStatus(
    String branchId,
    String budgetId,
    String status, {
    double? approvedAmount,
    String? approvedBy,
    List<Map<String, dynamic>>? changesSummary,
  }) async {
    final update = <String, dynamic>{'status': status};
    if (approvedAmount != null) update['approvedAmount'] = approvedAmount;
    if (approvedBy != null) update['approvedBy'] = approvedBy;
    if (changesSummary != null) update['changesSummary'] = changesSummary;
    update['approvedAt'] = FieldValue.serverTimestamp();
    await _col(branchId, 'budgets').doc(budgetId).update(update);
  }

  // ── Expenditure Request ──────────────────────────────────────────────────────
  @override
  Future<void> createExpenditureRequest(
    String branchId,
    ExpenditureRequestModel request,
  ) async {
    final id = request.id.isEmpty ? _uuid.v4() : request.id;
    await _col(branchId, 'expenditureRequests').doc(id).set(
      request.toFirestore(),
    );
  }

  @override
  Stream<List<ExpenditureRequestModel>> watchExpenditureRequests(
    String branchId, {
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _col(branchId, 'expenditureRequests');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
      (s) => s.docs
          .map((d) => ExpenditureRequestModel.fromFirestore(d.data(), d.id))
          .toList(),
    );
  }

  @override
  Future<void> approveExpenditure(
    String branchId,
    String requestId,
    String approvedBy,
    String approvedByName,
  ) async {
    final reqDoc = await _col(branchId, 'expenditureRequests').doc(requestId).get();
    final data = reqDoc.data();
    if (data == null) return;

    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final category = data['category'] as String? ?? '';
    final description = data['description'] as String? ?? '';

    final batch = _db.batch();

    // 1. Update request status
    batch.update(_col(branchId, 'expenditureRequests').doc(requestId), {
      'status': 'approved',
      'approvedAmount': amount,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create official expenditure ledger record
    final expId = _uuid.v4();
    final expRef = _col(branchId, 'expenditures').doc(expId);
    batch.set(expRef, {
      'approvedAmount': amount,
      'category': category,
      'description': description,
      'approvedBy': approvedBy,
      'sourceRequestId': requestId,
      'date': FieldValue.serverTimestamp(),
      'totalDisbursed': 0.0,
      'status': 'not-disbursed',
    });

    await batch.commit();
  }

  @override
  Future<void> rejectExpenditure(String branchId, String requestId, String reason) async {
    await _col(branchId, 'expenditureRequests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
    });
  }

  // ── Expenditures (approved ledger) ─────────────────────────────────────────
  @override
  Stream<List<ExpenditureModel>> watchExpenditures(String branchId) =>
      _col(branchId, 'expenditures').snapshots().map(
        (s) => s.docs
            .map((d) => ExpenditureModel.fromFirestore(d.data(), d.id))
            .toList(),
      );

  @override
  Future<ExpenditureModel?> getExpenditure(
    String branchId,
    String expenditureId,
  ) async {
    final doc =
        await _col(branchId, 'expenditures').doc(expenditureId).get();
    if (!doc.exists) return null;
    return ExpenditureModel.fromFirestore(doc.data()!, doc.id);
  }

  // ── Disbursements ─────────────────────────────────────────────────────────────
  @override
  Future<void> recordDisbursement(
    String branchId,
    String expenditureId,
    DisbursementModel disbursement,
  ) async {
    final expDoc = await _col(branchId, 'expenditures').doc(expenditureId).get();
    if (!expDoc.exists) throw Exception('Expenditure ledger record not found');

    final exp = ExpenditureModel.fromFirestore(expDoc.data()!, expenditureId);

    // Over-disbursement guard!
    if (disbursement.amountDisbursed > exp.remainingBalance) {
      throw Exception(
        'Disbursement amount (₦${disbursement.amountDisbursed}) exceeds remaining balance (₦${exp.remainingBalance})',
      );
    }

    final newTotal = exp.totalDisbursed + disbursement.amountDisbursed;
    final newStatus = newTotal >= exp.approvedAmount
        ? 'fully-disbursed'
        : 'partially-disbursed';

    final batch = _db.batch();

    // Add disbursement subcollection record
    final id = disbursement.id.isEmpty ? _uuid.v4() : disbursement.id;
    final disRef = _col(branchId, 'expenditures')
        .doc(expenditureId)
        .collection('disbursements')
        .doc(id);
    batch.set(disRef, disbursement.toFirestore());

    // Update parent expenditure ledger state
    batch.update(_col(branchId, 'expenditures').doc(expenditureId), {
      'totalDisbursed': newTotal,
      'status': newStatus,
    });

    await batch.commit();
  }

  @override
  Stream<List<DisbursementModel>> watchDisbursements(
    String branchId,
    String expenditureId,
  ) =>
      _col(branchId, 'expenditures')
          .doc(expenditureId)
          .collection('disbursements')
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => DisbursementModel.fromFirestore(d.data(), d.id))
                .toList(),
          );
}
