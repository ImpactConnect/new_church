import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_model.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_meeting_model.dart';
import 'package:cms/src/repositories/sub_group_repository.dart';

class FirebaseSubGroupRepository implements SubGroupRepository {
  FirebaseSubGroupRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _groupsCol(String branchId) =>
      _db.collection('branches').doc(branchId).collection('sub_groups');

  CollectionReference<Map<String, dynamic>> _meetingsCol(String branchId, String groupId) =>
      _groupsCol(branchId).doc(groupId).collection('meetings');

  @override
  Stream<List<SubGroupModel>> watchSubGroups(String branchId) {
    return _groupsCol(branchId).snapshots().map(
          (s) => s.docs.map((d) => SubGroupModel.fromFirestore(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<List<SubGroupModel>> getSubGroups(String branchId) async {
    final snap = await _groupsCol(branchId).get();
    return snap.docs.map((d) => SubGroupModel.fromFirestore(d.data(), d.id)).toList();
  }

  @override
  Future<void> createSubGroup(SubGroupModel group) async {
    final id = group.id.isEmpty ? _uuid.v4() : group.id;
    final docRef = _groupsCol(group.branchId).doc(id);
    final data = group.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  @override
  Future<void> updateSubGroup(SubGroupModel group) async {
    await _groupsCol(group.branchId).doc(group.id).update(group.toFirestore());
  }

  @override
  Future<void> deleteSubGroup(String branchId, String groupId) async {
    await _groupsCol(branchId).doc(groupId).delete();
  }

  @override
  Future<void> assignMembersToGroup(String branchId, String groupId, List<String> memberIds) async {
    await _groupsCol(branchId).doc(groupId).update({
      'memberIds': memberIds,
    });
  }

  @override
  Stream<List<SubGroupMeetingModel>> watchMeetingsForGroup(String branchId, String groupId) {
    return _meetingsCol(branchId, groupId)
        .orderBy('meetingDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => SubGroupMeetingModel.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Stream<List<SubGroupMeetingModel>> watchAllSubGroupMeetings(String branchId) {
    return _db
        .collectionGroup('meetings')
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .map((s) => s.docs.map((d) => SubGroupMeetingModel.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Future<void> recordMeeting(SubGroupMeetingModel meeting) async {
    final id = meeting.id.isEmpty ? _uuid.v4() : meeting.id;
    final docRef = _meetingsCol(meeting.branchId, meeting.subGroupId).doc(id);
    await docRef.set(meeting.toFirestore());
  }
}
