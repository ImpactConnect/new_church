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
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
