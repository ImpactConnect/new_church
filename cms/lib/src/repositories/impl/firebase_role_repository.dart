import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/features/roles/models/role_model.dart';
import 'package:cms/src/repositories/role_repository.dart';

class FirebaseRoleRepository implements RoleRepository {
  FirebaseRoleRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _rolesCol(String branchId) =>
      _db.collection('branches').doc(branchId).collection('roles');

  @override
  Stream<List<RoleModel>> watchRoles(String branchId) =>
      _rolesCol(branchId).snapshots().map(
        (s) =>
            s.docs.map((d) => RoleModel.fromFirestore(d.data(), d.id)).toList(),
      );

  @override
  Future<List<RoleModel>> getRoles(String branchId) async {
    final snap = await _rolesCol(branchId).get();
    return snap.docs.map((d) => RoleModel.fromFirestore(d.data(), d.id)).toList();
  }

  /// Assign a role to a member by updating their member document's `roleId`.
  /// NOTE: Updating Custom Claims (branchId/roleId) must be done via a
  /// Cloud Function — this client-side call only updates the Firestore document.
  /// The user will need to sign out and back in to pick up the new claims.
  @override
  Future<void> assignRole(
    String branchId,
    String memberId,
    String roleId,
  ) async {
    await _db
        .collection('branches')
        .doc(branchId)
        .collection('members')
        .doc(memberId)
        .update({'roleId': roleId});
  }

  @override
  Future<void> removeRole(String branchId, String memberId) async {
    await _db
        .collection('branches')
        .doc(branchId)
        .collection('members')
        .doc(memberId)
        .update({'roleId': FieldValue.delete()});
  }

  @override
  Future<void> createCustomRole(String branchId, String name, List<String> permissions) async {
    final docRef = _rolesCol(branchId).doc();
    await docRef.set({
      'name': name,
      'permissions': permissions,
      'isCustom': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateCustomRole(String branchId, String roleId, String name, List<String> permissions) async {
    await _rolesCol(branchId).doc(roleId).update({
      'name': name,
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCustomRole(String branchId, String roleId) async {
    await _rolesCol(branchId).doc(roleId).delete();
  }

  @override
  Future<void> provisionStaffAccount({
    required String branchId,
    required String name,
    required String email,
    required String password,
    required String roleId,
    String? phone,
  }) async {
    String uid = 'staff_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create account in Auth via temporary app
    FirebaseApp? tempApp;
    try {
      final appName = 'TempStaffAuth_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: _db.app.options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCred.user != null) {
        uid = userCred.user!.uid;
        await userCred.user!.updateDisplayName(name);
      }
    } catch (e) {
      // If user exists or auth error, fallback to random uid or existing
    } finally {
      await tempApp?.delete();
    }

    final batch = _db.batch();

    // 2. Write /users/{uid}
    final userRef = _db.collection('users').doc(uid);
    batch.set(userRef, {
      'uid': uid,
      'email': email,
      'displayName': name,
      'branchId': branchId,
      'roleId': roleId,
      'phone': phone ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // 3. Write /branches/{branchId}/members/{uid}
    final parts = name.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : 'Staff';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Officer';

    final memberRef = _db.collection('branches').doc(branchId).collection('members').doc(uid);
    batch.set(memberRef, {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone ?? '',
      'roleId': roleId,
      'isStaff': true,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Seeds the 3 default roles with their permission catalogs.
  /// Call once during initial church setup. Safe to re-run (uses set+merge).
  @override
  Future<void> seedRoles(String branchId) async {
    final batch = _db.batch();
    for (final entry in AppRole.defaultPermissions.entries) {
      final roleId = entry.key;
      final permissions = entry.value;
      final docRef = _rolesCol(branchId).doc(roleId);
      batch.set(docRef, {
        'name': RoleModel(
          id: roleId,
          name: '',
          permissions: permissions,
        ).displayName,
        'permissions': permissions,
        'scope': {'type': 'branch'},
        'isCustom': false,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
