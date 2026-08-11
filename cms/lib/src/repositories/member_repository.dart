import 'package:cms/src/features/members/models/member_model.dart';

/// Abstract interface for the Member repository.
/// Web impl → direct Firestore; Desktop impl → Isar + outbox sync.
abstract class MemberRepository {
  /// Stream all members for a given branch.
  Stream<List<MemberModel>> watchMembers(String branchId);

  /// Fetch a single member by ID.
  Future<MemberModel?> getMember(String branchId, String memberId);

  /// Create or replace a member document.
  Future<void> saveMember(String branchId, MemberModel member);

  /// Soft-delete: set memberStatus = 'inactive' rather than deleting.
  Future<void> updateMemberStatus(
    String branchId,
    String memberId,
    String status,
  );

  /// Batch import from CSV/Excel — caller provides validated list.
  Future<void> importMembers(
    String branchId,
    List<MemberModel> members,
    String importBatchId,
  );
}
