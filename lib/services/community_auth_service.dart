import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_user.dart';

class CommunityAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _userIdKey = 'community_user_id';
  static const String _usernameKey = 'community_username';
  static const String _displayNameKey = 'community_display_name';
  static const String _memberIdKey = 'community_member_id';
  static const String _roleKey = 'community_role';

  Future<CommunityUser?> signIn(String rawUsername, String rawPassword) async {
    final usernameInput = rawUsername.trim();
    final passwordInput = rawPassword.trim();
    final lowerUsername = usernameInput.toLowerCase();

    if (usernameInput.isEmpty || passwordInput.isEmpty) {
      return null;
    }

    try {
      DocumentSnapshot? matchedDoc;

      // ─── PHASE 1: UNAUTHENTICATED LOOKUP ─────────────────────────────────
      // The top-level 'members' collection has `allow read: if true` in Firestore rules.
      // We MUST search here BEFORE Firebase Auth — branch subcollection requires auth.

      Future<DocumentSnapshot?> findInPublicMembers(String field, String value) async {
        try {
          final snap = await _firestore
              .collection('members')
              .where(field, isEqualTo: value)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) return snap.docs.first;
        } catch (_) {}
        return null;
      }

      // Search top-level members by username (lowercased, then exact)
      matchedDoc = await findInPublicMembers('username', lowerUsername);
      matchedDoc ??= await findInPublicMembers('username', usernameInput);

      // Fallback: user typed their email address instead of username
      matchedDoc ??= await findInPublicMembers('email', lowerUsername);
      matchedDoc ??= await findInPublicMembers('email', usernameInput);

      if (matchedDoc == null) {
        // User doesn't exist even in the public collection
        return null;
      }

      final userData = matchedDoc.data() as Map<String, dynamic>;
      String? email = (userData['email'] as String?)?.trim();

      // If no email stored, infer the generated app email
      if (email == null || email.isEmpty) {
        final storedUsername = (userData['username'] as String?)?.trim() ?? lowerUsername;
        email = '$storedUsername@impactconnect.app';
      }

      // ─── PHASE 2: FIREBASE AUTH ───────────────────────────────────────────
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: passwordInput);
      } catch (authError) {
        if (authError is FirebaseAuthException && authError.code == 'user-not-found') {
          // Auth user was never created — try to provision it now
          try {
            await _auth.createUserWithEmailAndPassword(email: email, password: passwordInput);
          } catch (_) {
            return null;
          }
        } else {
          // Wrong password or other auth error
          return null;
        }
      }

      // ─── PHASE 3: ENRICH FROM BRANCH COLLECTION (now authenticated) ──────
      // Now that Firebase Auth is established we can safely read branch subcollection
      DocumentSnapshot resolvedDoc = matchedDoc;
      try {
        final branchSnap = await _firestore
            .collection('branches')
            .doc('default-branch')
            .collection('members')
            .doc(matchedDoc.id)
            .get();
        if (branchSnap.exists) {
          // Prefer branch data if it exists (it's the canonical CMS source)
          resolvedDoc = branchSnap;
        }
      } catch (_) {
        // If still no access, stick with top-level data — it's fine
      }

      final finalData = resolvedDoc.data() as Map<String, dynamic>;

      String displayName = (finalData['name'] as String?)?.trim() ?? '';
      if (displayName.isEmpty) {
        final fn = (finalData['firstName'] as String?)?.trim() ?? '';
        final ln = (finalData['lastName'] as String?)?.trim() ?? '';
        displayName = '$fn $ln'.trim();
      }
      if (displayName.isEmpty) {
        displayName = (finalData['username'] as String?) ?? 'Member';
      }

      final CommunityUser user = CommunityUser(
        id: resolvedDoc.id,
        username: finalData['username'] ?? lowerUsername,
        displayName: displayName,
        memberId: resolvedDoc.id,
        role: finalData['role'] ?? 'member',
        accountStatus: 'active',
      );

      await _saveUserToDevice(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserToDevice(CommunityUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_displayNameKey, user.displayName);
    await prefs.setString(_memberIdKey, user.memberId);
    await prefs.setString(_roleKey, user.role);
  }

  Future<CommunityUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is logged in
    final userId = prefs.getString(_userIdKey);
    if (userId == null) return null;

    // Retrieve user details from SharedPreferences
    return CommunityUser(
      id: userId,
      username: prefs.getString(_usernameKey) ?? '',
      displayName: prefs.getString(_displayNameKey) ?? '',
      memberId: prefs.getString(_memberIdKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'member',
    );
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_memberIdKey);
    await prefs.remove(_roleKey);
  }

  Future<void> generateMockUsers() async {
    try {
      final List<Map<String, dynamic>> mockUsers = [
        {
          'username': 'mock_user_1',
          'display_name': 'John Doe',
          'member_id': 'member_001',
          'role': 'member',
          'account_status': 'active',
          'password': 'password123',
          'last_login': null,
        },
        {
          'username': 'mock_user_2',
          'display_name': 'Jane Smith',
          'member_id': 'member_002',
          'role': 'member',
          'account_status': 'active',
          'password': 'password456',
          'last_login': null,
        },
        {
          'username': 'admin_user',
          'display_name': 'Church Admin',
          'member_id': 'admin_001',
          'role': 'admin',
          'account_status': 'active',
          'password': 'adminpass',
          'last_login': null,
        }
      ];

      final WriteBatch batch = _firestore.batch();
      for (var userData in mockUsers) {
        final docRef =
            _firestore.collection('community_users').doc(userData['username']);
        batch.set(docRef, userData);
      }
      await batch.commit();
      print('Mock users generated successfully');
    } catch (e) {
      print('Error generating mock users: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String rawUsername) async {
    final usernameInput = rawUsername.trim();
    final lowerUsername = usernameInput.toLowerCase();

    try {
      DocumentSnapshot? doc;

      // Stage 1: top-level 'members' (publicly readable — no auth needed)
      var snap = await _firestore
          .collection('members')
          .where('username', isEqualTo: lowerUsername)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) doc = snap.docs.first;

      // Stage 2: top-level by email
      if (doc == null) {
        snap = await _firestore
            .collection('members')
            .where('email', isEqualTo: lowerUsername)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) doc = snap.docs.first;
      }

      // Stage 3: exact case match
      if (doc == null) {
        snap = await _firestore
            .collection('members')
            .where('username', isEqualTo: usernameInput)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) doc = snap.docs.first;
      }

      if (doc == null) {
        throw Exception('User not found');
      }

      final userData = doc.data() as Map<String, dynamic>;
      String? email = (userData['email'] as String?)?.trim();

      if (email == null || email.isEmpty) {
        final u = (userData['username'] as String?)?.trim() ?? lowerUsername;
        email = '$u@impactconnect.app';
      }

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Optional: Method to clear mock users
  Future<void> clearMockUsers() async {
    try {
      final mockUsernames = ['mock_user_1', 'mock_user_2', 'admin_user'];

      final WriteBatch batch = _firestore.batch();

      for (var username in mockUsernames) {
        final docRef = _firestore.collection('community_users').doc(username);
        batch.delete(docRef);
      }

      await batch.commit();
      print('Mock users cleared successfully');
    } catch (e) {
      print('Error clearing mock users: $e');
    }
  }
}
