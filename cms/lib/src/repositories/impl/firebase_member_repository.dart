import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/repositories/member_repository.dart';
import 'package:uuid/uuid.dart';

/// Web implementation — direct Firestore reads/writes.
class FirebaseMemberRepository implements MemberRepository {
  FirebaseMemberRepository({required FirebaseFirestore firestore})
    : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('members');

  @override
  Stream<List<MemberModel>> watchMembers(String branchId) {
    final effectiveBranchId =
        (branchId.isEmpty || branchId == 'hq' || branchId == 'all')
            ? 'default-branch'
            : branchId;
    return _col(effectiveBranchId).snapshots().map(
      (snap) => snap.docs
          .map((d) => MemberModel.fromFirestore(d.data(), d.id))
          .toList(),
    );
  }

  @override
  Future<MemberModel?> getMember(String branchId, String memberId) async {
    final doc = await _col(branchId).doc(memberId).get();
    if (!doc.exists) return null;
    return MemberModel.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> saveMember(String branchId, MemberModel member) async {
    final id = member.id.isEmpty ? _uuid.v4() : member.id;
    await _col(branchId).doc(id).set(member.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updateMemberStatus(
    String branchId,
    String memberId,
    String status,
  ) async {
    await _col(branchId).doc(memberId).update({'memberStatus': status});
  }

  @override
  Future<void> deleteMember(String branchId, String memberId) async {
    await _col(branchId).doc(memberId).delete();
  }

  @override
  Future<void> importMembers(
    String branchId,
    List<MemberModel> members,
    String importBatchId,
  ) async {
    // Chunk into batches of 500 (Firestore limit)
    const chunkSize = 500;
    for (var i = 0; i < members.length; i += chunkSize) {
      final chunk = members.sublist(
        i,
        i + chunkSize > members.length ? members.length : i + chunkSize,
      );
      final batch = _db.batch();
      for (final m in chunk) {
        final id = m.id.isEmpty ? _uuid.v4() : m.id;
        final data = m.toFirestore()
          ..['importBatchId'] = importBatchId
          ..['importedAt'] = DateTime.now().toIso8601String();
        batch.set(_col(branchId).doc(id), data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
