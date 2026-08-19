import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';
import 'package:cms/src/repositories/branch_repository.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Stream<BranchModel?> watchBranch(String branchId) =>
      _db.collection('branches').doc(branchId).snapshots().map(
        (doc) => doc.exists ? BranchModel.fromFirestore(doc.data()!, doc.id) : null,
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

  @override
  Future<void> deleteBranch(String branchId) async {
    await _db.collection('branches').doc(branchId).delete();
  }

  @override
  Future<void> createBranchWithPastor({
    required BranchModel branch,
    required String pastorName,
    required String pastorEmail,
    required String password,
  }) async {
    final branchId = branch.id.isEmpty ? _uuid.v4() : branch.id;
    String pastorUid = _uuid.v4();

    // 1. Create account in Firebase Auth via temporary secondary app instance
    FirebaseApp? tempApp;
    try {
      final appName = 'TempBranchAuth_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: _db.app.options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCred = await tempAuth.createUserWithEmailAndPassword(
        email: pastorEmail,
        password: password,
      );
      if (userCred.user != null) {
        pastorUid = userCred.user!.uid;
        await userCred.user!.updateDisplayName(pastorName);
      }
    } catch (e) {
      // Fallback to random UID if account creation was handled externally
    } finally {
      await tempApp?.delete();
    }

    // 2. Save branch document
    final newBranch = BranchModel(
      id: branchId,
      name: branch.name,
      address: branch.address,
      pastorInCharge: pastorName,
      phone: branch.phone,
      pastorId: pastorUid,
      pastorEmail: pastorEmail,
      city: branch.city,
      state: branch.state,
      createdAt: branch.createdAt,
    );

    final batch = _db.batch();
    batch.set(_db.collection('branches').doc(branchId), newBranch.toFirestore(), SetOptions(merge: true));

    // 3. Register user record in Firestore under /users collection for this branch
    final userRef = _db.collection('users').doc(pastorUid);
    batch.set(userRef, {
      'uid': pastorUid,
      'email': pastorEmail,
      'displayName': pastorName,
      'branchId': branchId,
      'roleId': 'branchPastor',
      'createdAt': DateTime.now().toIso8601String(),
      'tempPassword': password,
    }, SetOptions(merge: true));


    // 4. Seed the branchPastor role for this branch
    final rolesRef = _db.collection('branches').doc(branchId).collection('roles');
    batch.set(rolesRef.doc('branchPastor'), {
      'name': 'Branch Pastor',
      'permissions': [
        'isBranchPastor',
        'manageMembers',
        'recordAttendance',
        'manageEvents',
        'recordIncome',
        'createBudgetRequest',
        'createExpenditureRequest',
        'sendIncomeReport',
        'viewBranchReports',
      ],
    });

    await batch.commit();
  }
}

