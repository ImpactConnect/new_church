import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/features/auth/models/cms_user_model.dart';
import 'package:cms/src/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web & Native implementation — delegates to Firebase Auth + Firestore
/// with local SharedPreferences caching and deterministic role resolution
/// to eliminate cross-role leaks and network fluctuation glitches.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
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

      // Prevent cross-user data leakage if auth user changed
      if (_currentUser != null && _currentUser!.uid != user.uid) {
        _currentUser = null;
      }

      try {
        _currentUser = await _buildCmsUser(user);
        return _currentUser;
      } catch (e) {
        // On network error during authStateChanges, load cached user for THIS uid
        final cached = await _getCachedUser(user.uid);
        if (cached != null) {
          _currentUser = cached;
          return _currentUser;
        }

        // If in-memory user matches THIS uid, retain it
        if (_currentUser != null && _currentUser!.uid == user.uid) {
          return _currentUser;
        }

        // Infer role strictly from email if available
        final fallbackRole = _inferRoleFromEmail(user.email ?? '');
        if (fallbackRole != null) {
          _currentUser = CmsUserModel(
            uid: user.uid,
            email: user.email ?? '',
            branchId: 'default-branch',
            roleId: fallbackRole,
            permissions: AppRole.defaultPermissions[fallbackRole] ?? [],
            displayName: user.displayName,
          );
          return _currentUser;
        }

        rethrow;
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
        await user.getIdToken(true);
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

    // If claims are missing, fall back to Firestore /users/{uid} document
    if (rawBranchId.isEmpty || rawRoleId.isEmpty) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache));
        if (userDoc.exists && userDoc.data() != null) {
          rawBranchId = userDoc.data()!['branchId'] as String? ?? rawBranchId;
          rawRoleId = userDoc.data()!['roleId'] as String? ?? rawRoleId;
        }
      } catch (_) {}
    }

    // If Firestore fetch failed (network fluctuation), check persistent local cache for THIS uid
    if (rawRoleId.isEmpty) {
      final cached = await _getCachedUser(user.uid);
      if (cached != null && cached.roleId.isNotEmpty) {
        rawRoleId = cached.roleId;
        if (rawBranchId.isEmpty) rawBranchId = cached.branchId;
      }
    }

    // Deterministic email-based role fallback if still empty
    if (rawRoleId.isEmpty) {
      final inferred = _inferRoleFromEmail(user.email ?? '');
      if (inferred != null) {
        rawRoleId = inferred;
      }
    }

    final branchId = rawBranchId.isNotEmpty ? rawBranchId : 'default-branch';
    final roleId = rawRoleId.isNotEmpty ? rawRoleId : AppRole.leadPastor;

    List<String> permissions = [];
    try {
      permissions = await _fetchPermissions(branchId, roleId);
    } catch (_) {}

    if (permissions.isEmpty) {
      permissions = AppRole.defaultPermissions[roleId] ?? [];
    }

    final cmsUser = CmsUserModel(
      uid: user.uid,
      email: user.email ?? '',
      branchId: branchId,
      roleId: roleId,
      permissions: permissions,
      displayName: user.displayName,
    );

    // Save to persistent local SharedPreferences cache for offline & network fluctuation safety
    _cacheUser(cmsUser);

    return cmsUser;
  }

  Future<List<String>> _fetchPermissions(
    String branchId,
    String roleId,
  ) async {
    try {
      final doc = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('roles')
          .doc(roleId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        final perms = List<String>.from(doc.data()!['permissions'] ?? []);
        if (perms.isNotEmpty) return perms;
      }
    } catch (_) {}
    return AppRole.defaultPermissions[roleId] ?? [];
  }

  String? _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase().trim();
    if (lower.contains('secretary')) return AppRole.secretary;
    if (lower.contains('finance')) return AppRole.financeDept;
    if (lower.contains('asset')) return AppRole.assetManager;
    if (lower.contains('branch')) return AppRole.branchPastor;
    if (lower.contains('pastor') || lower.contains('admin') || lower.contains('lead')) {
      return AppRole.leadPastor;
    }
    return null;
  }

  Future<void> _cacheUser(CmsUserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cms_user_profile_${user.uid}', jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<CmsUserModel?> _getCachedUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cms_user_profile_$uid');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return CmsUserModel.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}
