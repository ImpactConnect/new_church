import 'package:cms/src/features/auth/models/cms_user_model.dart';

/// Abstract auth service — wraps Firebase Auth + Custom Claims.
abstract class AuthRepository {
  /// Stream of the currently signed-in CMS user (null = logged out).
  Stream<CmsUserModel?> get authStateChanges;

  /// Sign in with email + password.
  Future<CmsUserModel> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Sign out and clear local session.
  Future<void> signOut();

  /// Force-refresh the ID token to pick up updated custom claims
  /// (e.g. after a role is assigned).
  Future<void> refreshToken();

  /// Returns the current user or null if not authenticated.
  CmsUserModel? get currentUser;
}
