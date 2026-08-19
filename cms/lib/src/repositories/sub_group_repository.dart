import 'package:cms/src/features/sub_groups/models/sub_group_model.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_meeting_model.dart';

abstract class SubGroupRepository {
  Stream<List<SubGroupModel>> watchSubGroups(String branchId);
  Future<List<SubGroupModel>> getSubGroups(String branchId);
  Future<void> createSubGroup(SubGroupModel group);
  Future<void> updateSubGroup(SubGroupModel group);
  Future<void> deleteSubGroup(String branchId, String groupId);
  Future<void> assignMembersToGroup(String branchId, String groupId, List<String> memberIds);

  Stream<List<SubGroupMeetingModel>> watchMeetingsForGroup(String branchId, String groupId);
  Stream<List<SubGroupMeetingModel>> watchAllSubGroupMeetings(String branchId);
  Future<void> recordMeeting(SubGroupMeetingModel meeting);
}
