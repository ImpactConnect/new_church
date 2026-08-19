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
      try {
        _currentUser = await _buildCmsUser(user);
        return _currentUser;
      } catch (e) {
        // Prevent accidental logout on transient network/token errors while idle
        if (_currentUser != null) return _currentUser;
        _currentUser = CmsUserModel(
          uid: user.uid,
          email: user.email ?? '',
          branchId: 'default-branch',
          roleId: AppRole.leadPastor,
          permissions: AppRole.defaultPermissions[AppRole.leadPastor] ?? [],
          displayName: user.displayName,
        );
        return _currentUser;
      }
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
      try {
        await user.getIdToken(false);
        _currentUser = await _buildCmsUser(user);
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Future<CmsUserModel> _buildCmsUser(User user) async {
    Map<String, dynamic> claims = {};
    try {
      final idTokenResult = await user.getIdTokenResult(false);
      claims = idTokenResult.claims ?? {};
    } catch (_) {}

    String rawBranchId = claims['branchId'] as String? ?? '';
    String rawRoleId = claims['roleId'] as String? ?? '';

    // If claims are missing (e.g. branch pastor — no custom claims set),
    // fall back to Firestore /users/{uid} document for branchId + roleId.
    if (rawBranchId.isEmpty || rawRoleId.isEmpty) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          rawBranchId = userDoc.data()!['branchId'] as String? ?? rawBranchId;
          rawRoleId = userDoc.data()!['roleId'] as String? ?? rawRoleId;
        }
      } catch (_) {}
    }

    // Default to 'default-branch' and 'leadPastor' for main church staff only
    final branchId = rawBranchId.isNotEmpty ? rawBranchId : 'default-branch';
    final roleId = rawRoleId.isNotEmpty ? rawRoleId : AppRole.leadPastor;

    List<String> permissions = [];
    try {
      permissions = await _fetchPermissions(branchId, roleId);
    } catch (_) {}

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
