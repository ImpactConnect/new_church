import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cms/src/features/auth/models/cms_user_model.dart';
import 'package:cms/src/repositories/auth_repository.dart';
import 'package:cms/src/repositories/member_repository.dart';
import 'package:cms/src/repositories/finance_repository.dart';
import 'package:cms/src/repositories/branch_repository.dart';
import 'package:cms/src/repositories/department_repository.dart';
import 'package:cms/src/repositories/role_repository.dart';
import 'package:cms/src/repositories/audit_log_repository.dart';
import 'package:cms/src/repositories/event_repository.dart';
import 'package:cms/src/repositories/announcement_repository.dart';
import 'package:cms/src/repositories/correspondence_repository.dart';
import 'package:cms/src/repositories/asset_repository.dart';
import 'package:cms/src/repositories/sub_group_repository.dart';
import 'package:cms/src/repositories/impl/firebase_auth_repository.dart';
import 'package:cms/src/repositories/impl/firebase_member_repository.dart';
import 'package:cms/src/repositories/impl/firebase_finance_repository.dart';
import 'package:cms/src/repositories/impl/firebase_branch_repository.dart';
import 'package:cms/src/repositories/impl/firebase_department_repository.dart';
import 'package:cms/src/repositories/impl/firebase_role_repository.dart';
import 'package:cms/src/repositories/impl/firebase_sub_group_repository.dart';
import 'package:cms/src/repositories/impl/firebase_audit_log_repository.dart';
import 'package:cms/src/repositories/impl/firebase_event_repository.dart';
import 'package:cms/src/repositories/impl/firebase_announcement_repository.dart';
import 'package:cms/src/repositories/impl/firebase_correspondence_repository.dart';
import 'package:cms/src/repositories/impl/firebase_asset_repository.dart';
import 'package:cms/src/repositories/communication_repository.dart';
import 'package:cms/src/repositories/impl/firebase_communication_repository.dart';
import 'package:cms/src/features/communication/services/messaging_service.dart';
import 'package:cms/src/repositories/group_income_repository.dart';
import 'package:cms/src/repositories/impl/firebase_group_income_repository.dart';
import 'package:cms/src/repositories/impl/isar_repositories.dart';

// ── Firebase singletons ───────────────────────────────────────────────────────

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

// ── Auth ──────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firestoreProvider);
  final firebaseImpl = FirebaseAuthRepository(auth: auth, firestore: db);
  if (!kIsWeb) return IsarAuthRepository(delegate: firebaseImpl);
  return firebaseImpl;
});

final cmsUserProvider = StreamProvider<CmsUserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Members ───────────────────────────────────────────────────────────────────

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  final firebaseImpl = FirebaseMemberRepository(firestore: db);
  if (!kIsWeb) return IsarMemberRepository(delegate: firebaseImpl);
  return firebaseImpl;
});

// ── Finance ───────────────────────────────────────────────────────────────────

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  final firebaseImpl = FirebaseFinanceRepository(firestore: db);
  if (!kIsWeb) return IsarFinanceRepository(delegate: firebaseImpl);
  return firebaseImpl;
});

// ── Branches ──────────────────────────────────────────────────────────────────

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseBranchRepository(firestore: db);
});

// ── Departments ───────────────────────────────────────────────────────────────

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseDepartmentRepository(firestore: db);
});

// ── Roles ─────────────────────────────────────────────────────────────────────

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseRoleRepository(firestore: db);
});

// ── Sub-Groups ────────────────────────────────────────────────────────────────

final subGroupRepositoryProvider = Provider<SubGroupRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseSubGroupRepository(firestore: db);
});

// ── Group Income ─────────────────────────────────────────────────────────────

final groupIncomeRepositoryProvider = Provider<GroupIncomeRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseGroupIncomeRepository(firestore: db);
});

// ── Audit Log ─────────────────────────────────────────────────────────────────

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseAuditLogRepository(firestore: db);
});

// ── Events & Attendance ───────────────────────────────────────────────────────

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseEventRepository(firestore: db);
});

// ── Announcements ─────────────────────────────────────────────────────────────

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseAnnouncementRepository(firestore: db);
});

// ── Correspondence ────────────────────────────────────────────────────────────

final correspondenceRepositoryProvider = Provider<CorrespondenceRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseCorrespondenceRepository(firestore: db);
});

// ── Assets ────────────────────────────────────────────────────────────────────

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseAssetRepository(firestore: db);
});

// ── Communication ─────────────────────────────────────────────────────────────

final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirebaseCommunicationRepository(firestore: db);
});

final messagingServiceProvider = Provider<MessagingService>((ref) {
  final db = ref.watch(firestoreProvider);
  return MessagingService(firestore: db);
});

// ── Convenience: current & selected branch ID ─────────────────────────────────

final currentBranchIdProvider = Provider<String>((ref) {
  return ref.watch(cmsUserProvider).valueOrNull?.branchId ?? 'default-branch';
});

final selectedBranchIdProvider = StateProvider<String>((ref) {
  final user = ref.watch(cmsUserProvider).valueOrNull;
  return user?.branchId ?? 'default-branch';
});

