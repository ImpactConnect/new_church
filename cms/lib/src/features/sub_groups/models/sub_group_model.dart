import 'package:equatable/equatable.dart';

class SubGroupModel extends Equatable {
  const SubGroupModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.type, // 'houseFellowship' | 'sundaySchool' | 'bibleStudy' | 'custom'
    required this.recordingOfficerMemberId,
    this.officerName,
    this.memberIds = const [],
    this.meetingDay = 'Sunday',
    this.meetingTime = '17:00',
    this.locationAddress = '',
    this.createdAt,
  });

  final String id;
  final String branchId;
  final String name;
  final String type;
  final String recordingOfficerMemberId;
  final String? officerName;
  final List<String> memberIds;
  final String meetingDay;
  final String meetingTime;
  final String locationAddress;
  final String? createdAt;

  factory SubGroupModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubGroupModel(
      id: id,
      branchId: data['branchId'] as String? ?? 'default-branch',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'houseFellowship',
      recordingOfficerMemberId: data['recordingOfficerMemberId'] as String? ?? '',
      officerName: data['officerName'] as String?,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      meetingDay: data['meetingDay'] as String? ?? 'Sunday',
      meetingTime: data['meetingTime'] as String? ?? '17:00',
      locationAddress: data['locationAddress'] as String? ?? '',
      createdAt: data['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'branchId': branchId,
    'name': name,
    'type': type,
    'recordingOfficerMemberId': recordingOfficerMemberId,
    if (officerName != null) 'officerName': officerName,
    'memberIds': memberIds,
    'meetingDay': meetingDay,
    'meetingTime': meetingTime,
    'locationAddress': locationAddress,
    if (createdAt != null) 'createdAt': createdAt,
  };

  String get typeDisplayName => switch (type) {
    'houseFellowship' => 'House Fellowship',
    'sundaySchool' => 'Sunday School Class',
    'bibleStudy' => 'Bible Study Unit',
    _ => 'Sub-Group',
  };

  @override
  List<Object?> get props => [
    id,
    branchId,
    name,
    type,
    recordingOfficerMemberId,
    memberIds,
    meetingDay,
    meetingTime,
    locationAddress,
  ];
}
