import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:cms/src/features/finance/models/group_income_model.dart';
import 'package:cms/src/repositories/group_income_repository.dart';

class FirebaseGroupIncomeRepository implements GroupIncomeRepository {
  FirebaseGroupIncomeRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('group_incomes');

  @override
  Stream<List<GroupIncomeRecordModel>> watchGroupIncomes(
    String branchId,
    String entityId,
  ) {
    return _col(branchId)
        .where('entityId', isEqualTo: entityId)
        .snapshots()
        .map(
          (s) {
            final list = s.docs
                .map((d) => GroupIncomeRecordModel.fromFirestore(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          },
        );
  }

  @override
  Stream<List<GroupIncomeRecordModel>> watchAllBranchGroupIncomes(
    String branchId,
  ) {
    return _col(branchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => GroupIncomeRecordModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<void> recordGroupIncome(
    String branchId,
    GroupIncomeRecordModel record,
  ) async {
    final id = record.id.isEmpty ? _uuid.v4() : record.id;
    final docRef = _col(branchId).doc(id);

    final batch = _db.batch();
    batch.set(docRef, record.toFirestore(), SetOptions(merge: true));

    // If individual member donation, also append giving summary to member profile
    if (record.donorMemberId != null && record.donorMemberId!.isNotEmpty) {
      final memberRef = _db
          .collection('branches')
          .doc(branchId)
          .collection('members')
          .doc(record.donorMemberId);

      batch.set(
        memberRef,
        {
          'lastGivingDate': record.date.toIso8601String(),
          'totalGroupDonations': FieldValue.increment(record.amount),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> deleteGroupIncome(
    String branchId,
    String recordId,
  ) async {
    await _col(branchId).doc(recordId).delete();
  }
}
