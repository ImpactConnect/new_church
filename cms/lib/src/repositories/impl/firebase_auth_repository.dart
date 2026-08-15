import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/features/auth/models/cms_user_model.dart';
import 'package:cms/src/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Web implementation — delegates directly to Firebase Auth + Firestore
/// to resolve fine-grained permissions from the role document.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  CmsUserModel? _currentUser;

  @override
  CmsUserModel? get currentUser => _currentUser;

  @override
  Stream<CmsUserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _currentUser = null;
        return null;
      }
      _currentUser = await _buildCmsUser(user);
      return _currentUser;
    });
  }

  @override
  Future<CmsUserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final cmsUser = await _buildCmsUser(cred.user!);
    _currentUser = cmsUser;
    return cmsUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _auth.signOut();
  }

  @override
  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);
      _currentUser = await _buildCmsUser(user);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Future<CmsUserModel> _buildCmsUser(User user) async {
    final idTokenResult = await user.getIdTokenResult();
    final claims = idTokenResult.claims ?? {};
    final rawBranchId = claims['branchId'] as String? ?? '';
    final rawRoleId = claims['roleId'] as String? ?? '';

    // Default to 'default-branch' and 'leadPastor' if claims are not yet propagated
    final branchId = rawBranchId.isNotEmpty ? rawBranchId : 'default-branch';
    final roleId = rawRoleId.isNotEmpty ? rawRoleId : AppRole.leadPastor;

    List<String> permissions = await _fetchPermissions(branchId, roleId);
    if (permissions.isEmpty) {
      permissions = AppRole.defaultPermissions[roleId] ?? [];
    }

    final updatedClaims = Map<String, dynamic>.from(claims);
    updatedClaims['branchId'] = branchId;
    updatedClaims['roleId'] = roleId;

    return CmsUserModel.fromClaims(
      uid: user.uid,
      email: user.email ?? '',
      claims: updatedClaims,
      permissions: permissions,
      displayName: user.displayName,
    );
  }

  Future<List<String>> _fetchPermissions(
    String branchId,
    String roleId,
  ) async {
    try {
      final doc =
          await _firestore
              .collection('branches')
              .doc(branchId)
              .collection('roles')
              .doc(roleId)
              .get();
      if (doc.exists && doc.data() != null) {
        final perms = List<String>.from(doc.data()!['permissions'] ?? []);
        if (perms.isNotEmpty) return perms;
      }
    } catch (_) {}
    return AppRole.defaultPermissions[roleId] ?? [];
  }
}
