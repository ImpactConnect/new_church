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
    final data = budget.toFirestore();
    // Preserve original fields for diff computation
    data['originalAmount'] = budget.requestedAmount;
    data['originalCategory'] = budget.category;
    if (budget.requestedDescription != null) {
      data['originalDescription'] = budget.requestedDescription;
    }
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col(branchId, 'budgets').doc(id).set(data);
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
    final data = doc.data();
    if (data == null) return;

    final requested = (data['requestedAmount'] as num?)?.toDouble() ?? 0;
    final category = data['category'] as String? ?? '';
    final description = data['requestedDescription'] as String? ?? '';
    final requestedBy = data['requestedBy'] as String? ?? '';

    // No changes — approve as-is
    final batch = _db.batch();
    batch.update(_col(branchId, 'budgets').doc(budgetId), {
      'status': 'approved',
      'approvedAmount': requested,
      'approvedCategory': category,
      'approvedDescription': description,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'changesSummary': [],
    });

    // Notify Finance
    final notifId = _uuid.v4();
    batch.set(
      _col(branchId, 'financeNotifications').doc(notifId),
      {
        'recipientUid': requestedBy,
        'type': 'budget-approved',
        'referenceId': budgetId,
        'message': 'Your budget request for "$category" was approved.',
        'changesSummary': [],
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  @override
  Future<void> approveBudgetWithEdits(
    String branchId,
    String budgetId,
    String approvedBy,
    String approvedByName, {
    required double approvedAmount,
    required String approvedCategory,
    required String approvedDescription,
  }) async {
    final doc = await _col(branchId, 'budgets').doc(budgetId).get();
    final data = doc.data();
    if (data == null) return;

    final origAmount = (data['originalAmount'] as num?)?.toDouble() ??
        (data['requestedAmount'] as num?)?.toDouble() ?? 0;
    final origCategory = data['originalCategory'] as String? ?? data['category'] as String? ?? '';
    final origDescription = data['originalDescription'] as String? ?? '';
    final requestedBy = data['requestedBy'] as String? ?? '';

    // Compute diff
    final changes = <Map<String, dynamic>>[];
    if (approvedAmount != origAmount) {
      changes.add({'field': 'amount', 'from': origAmount, 'to': approvedAmount});
    }
    if (approvedCategory != origCategory) {
      changes.add({'field': 'category', 'from': origCategory, 'to': approvedCategory});
    }
    if (approvedDescription != origDescription) {
      changes.add({'field': 'description', 'from': origDescription, 'to': approvedDescription});
    }

    final hasChanges = changes.isNotEmpty;
    final batch = _db.batch();

    batch.update(_col(branchId, 'budgets').doc(budgetId), {
      'status': 'approved',
      'approvedAmount': approvedAmount,
      'approvedCategory': approvedCategory,
      'approvedDescription': approvedDescription,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'changesSummary': changes,
    });

    // Notify Finance
    final notifId = _uuid.v4();
    final type = hasChanges ? 'budget-approved-with-changes' : 'budget-approved';
    final message = hasChanges
        ? 'Your budget request for "$approvedCategory" was approved with changes.'
        : 'Your budget request for "$approvedCategory" was approved.';

    batch.set(
      _col(branchId, 'financeNotifications').doc(notifId),
      {
        'recipientUid': requestedBy,
        'type': type,
        'referenceId': budgetId,
        'message': message,
        'changesSummary': changes,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  @override
  Future<void> rejectBudget(String branchId, String budgetId, String reason) async {
    final doc = await _col(branchId, 'budgets').doc(budgetId).get();
    final data = doc.data();
    final requestedBy = data?['requestedBy'] as String? ?? '';
    final category = data?['category'] as String? ?? '';

    final batch = _db.batch();
    batch.update(_col(branchId, 'budgets').doc(budgetId), {
      'status': 'rejected',
      'rejectionReason': reason,
    });

    // Notify Finance of rejection
    final notifId = _uuid.v4();
    batch.set(
      _col(branchId, 'financeNotifications').doc(notifId),
      {
        'recipientUid': requestedBy,
        'type': 'budget-rejected',
        'referenceId': budgetId,
        'message': 'Your budget request for "$category" was rejected. Reason: $reason',
        'changesSummary': [],
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
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
    final data = request.toFirestore();
    // Preserve original fields for diff
    data['originalAmount'] = request.amount;
    data['originalCategory'] = request.category;
    data['originalDescription'] = request.description;
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col(branchId, 'expenditureRequests').doc(id).set(data);
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
    final requestedBy = data['requestedBy'] as String? ?? '';

    final batch = _db.batch();

    // 1. Update request status
    batch.update(_col(branchId, 'expenditureRequests').doc(requestId), {
      'status': 'approved',
      'approvedAmount': amount,
      'approvedCategory': category,
      'approvedDescription': description,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'changesSummary': [],
    });

    // 2. Create official expenditure ledger record
    final expId = _uuid.v4();
    batch.set(_col(branchId, 'expenditures').doc(expId), {
      'approvedAmount': amount,
      'category': category,
      'description': description,
      'approvedBy': approvedBy,
      'sourceRequestId': requestId,
      'date': FieldValue.serverTimestamp(),
      'totalDisbursed': 0.0,
      'status': 'not-disbursed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Notify Finance
    batch.set(_col(branchId, 'financeNotifications').doc(_uuid.v4()), {
      'recipientUid': requestedBy,
      'type': 'expenditure-approved',
      'referenceId': requestId,
      'message': 'Your expenditure request for "$description" was approved.',
      'changesSummary': [],
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> approveExpenditureWithEdits(
    String branchId,
    String requestId,
    String approvedBy,
    String approvedByName, {
    required double approvedAmount,
    required String approvedCategory,
    required String approvedDescription,
  }) async {
    final reqDoc = await _col(branchId, 'expenditureRequests').doc(requestId).get();
    final data = reqDoc.data();
    if (data == null) return;

    final origAmount = (data['originalAmount'] as num?)?.toDouble() ??
        (data['amount'] as num?)?.toDouble() ?? 0;
    final origCategory = data['originalCategory'] as String? ?? data['category'] as String? ?? '';
    final origDescription = data['originalDescription'] as String? ?? data['description'] as String? ?? '';
    final requestedBy = data['requestedBy'] as String? ?? '';

    // Compute diff
    final changes = <Map<String, dynamic>>[];
    if (approvedAmount != origAmount) {
      changes.add({'field': 'amount', 'from': origAmount, 'to': approvedAmount});
    }
    if (approvedCategory != origCategory) {
      changes.add({'field': 'category', 'from': origCategory, 'to': approvedCategory});
    }
    if (approvedDescription != origDescription) {
      changes.add({'field': 'description', 'from': origDescription, 'to': approvedDescription});
    }

    final hasChanges = changes.isNotEmpty;
    final batch = _db.batch();

    // 1. Update request
    batch.update(_col(branchId, 'expenditureRequests').doc(requestId), {
      'status': 'approved',
      'approvedAmount': approvedAmount,
      'approvedCategory': approvedCategory,
      'approvedDescription': approvedDescription,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'changesSummary': changes,
    });

    // 2. Create expenditure ledger record with final approved values
    final expId = _uuid.v4();
    batch.set(_col(branchId, 'expenditures').doc(expId), {
      'approvedAmount': approvedAmount,
      'category': approvedCategory,
      'description': approvedDescription,
      'approvedBy': approvedBy,
      'sourceRequestId': requestId,
      'date': FieldValue.serverTimestamp(),
      'totalDisbursed': 0.0,
      'status': 'not-disbursed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Notify Finance
    final type = hasChanges ? 'expenditure-approved-with-changes' : 'expenditure-approved';
    final message = hasChanges
        ? 'Your expenditure request for "$approvedDescription" was approved with changes.'
        : 'Your expenditure request for "$approvedDescription" was approved.';

    batch.set(_col(branchId, 'financeNotifications').doc(_uuid.v4()), {
      'recipientUid': requestedBy,
      'type': type,
      'referenceId': requestId,
      'message': message,
      'changesSummary': changes,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> rejectExpenditure(String branchId, String requestId, String reason) async {
    final doc = await _col(branchId, 'expenditureRequests').doc(requestId).get();
    final data = doc.data();
    final requestedBy = data?['requestedBy'] as String? ?? '';
    final description = data?['description'] as String? ?? '';

    final batch = _db.batch();
    batch.update(_col(branchId, 'expenditureRequests').doc(requestId), {
      'status': 'rejected',
      'rejectionReason': reason,
    });

    batch.set(_col(branchId, 'financeNotifications').doc(_uuid.v4()), {
      'recipientUid': requestedBy,
      'type': 'expenditure-rejected',
      'referenceId': requestId,
      'message': 'Your expenditure request for "$description" was rejected. Reason: $reason',
      'changesSummary': [],
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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
    final doc = await _col(branchId, 'expenditures').doc(expenditureId).get();
    if (!doc.exists) return null;
    return ExpenditureModel.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Stream<List<BudgetModel>> watchApprovedBudgets(String branchId) =>
      _col(branchId, 'budgets')
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => BudgetModel.fromFirestore(d.data(), d.id))
                .toList(),
          );

  @override
  Stream<List<ExpenditureModel>> watchApprovedExpenditures(String branchId) =>
      _col(branchId, 'expenditures').snapshots().map(
        (s) => s.docs
            .map((d) => ExpenditureModel.fromFirestore(d.data(), d.id))
            .toList(),
      );

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

    // Over-disbursement guard (client-side; server-side Cloud Function is the final authority)
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

  // ── Finance Notifications ────────────────────────────────────────────────────
  @override
  Stream<List<FinanceNotificationModel>> watchNotifications(
    String branchId,
    String uid,
  ) =>
      _col(branchId, 'financeNotifications')
          .where('recipientUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => FinanceNotificationModel.fromFirestore(d.data(), d.id))
                .toList(),
          );

  @override
  Future<void> markNotificationRead(
    String branchId,
    String notificationId,
  ) async {
    await _col(branchId, 'financeNotifications').doc(notificationId).update({
      'read': true,
    });
  }
}
