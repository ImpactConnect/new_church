import 'package:equatable/equatable.dart';

class SubGroupMeetingModel extends Equatable {
  const SubGroupMeetingModel({
    required this.id,
    required this.subGroupId,
    required this.branchId,
    required this.meetingDate,
    required this.headCount,
    this.attendeeMemberIds = const [],
    this.offeringAmount = 0.0,
    this.notes = '',
    this.recordedByMemberId = '',
    this.recordedByName,
    this.createdAt,
  });

  final String id;
  final String subGroupId;
  final String branchId;
  final DateTime meetingDate;
  final int headCount;
  final List<String> attendeeMemberIds;
  final double offeringAmount;
  final String notes;
  final String recordedByMemberId;
  final String? recordedByName;
  final DateTime? createdAt;

  factory SubGroupMeetingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubGroupMeetingModel(
      id: id,
      subGroupId: data['subGroupId'] as String? ?? '',
      branchId: data['branchId'] as String? ?? 'default-branch',
      meetingDate: data['meetingDate'] != null
          ? (data['meetingDate'] is String
              ? DateTime.parse(data['meetingDate'])
              : (data['meetingDate'] as dynamic).toDate())
          : DateTime.now(),
      headCount: (data['headCount'] as num?)?.toInt() ?? 0,
      attendeeMemberIds: List<String>.from(data['attendeeMemberIds'] ?? []),
      offeringAmount: (data['offeringAmount'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String? ?? '',
      recordedByMemberId: data['recordedByMemberId'] as String? ?? '',
      recordedByName: data['recordedByName'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is String
              ? DateTime.parse(data['createdAt'])
              : (data['createdAt'] as dynamic).toDate())
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'subGroupId': subGroupId,
    'branchId': branchId,
    'meetingDate': meetingDate.toIso8601String(),
    'headCount': headCount,
    'attendeeMemberIds': attendeeMemberIds,
    'offeringAmount': offeringAmount,
    'notes': notes,
    'recordedByMemberId': recordedByMemberId,
    if (recordedByName != null) 'recordedByName': recordedByName,
    'createdAt': DateTime.now().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    subGroupId,
    branchId,
    meetingDate,
    headCount,
    attendeeMemberIds,
    offeringAmount,
    notes,
    recordedByMemberId,
  ];
}
