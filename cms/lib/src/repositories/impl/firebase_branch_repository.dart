import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';
import 'package:cms/src/repositories/branch_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseBranchRepository implements BranchRepository {
  FirebaseBranchRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  @override
  Stream<List<BranchModel>> watchBranches() =>
      _db.collection('branches').snapshots().map(
        (s) => s.docs
            .map((d) => BranchModel.fromFirestore(d.data(), d.id))
            .toList(),
      );

  @override
  Future<BranchModel?> getBranch(String branchId) async {
    final doc = await _db.collection('branches').doc(branchId).get();
    if (!doc.exists) return null;
    return BranchModel.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> saveBranch(BranchModel branch) async {
    final id = branch.id.isEmpty ? _uuid.v4() : branch.id;
    await _db
        .collection('branches')
        .doc(id)
        .set(branch.toFirestore(), SetOptions(merge: true));
  }
}
