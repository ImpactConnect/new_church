import 'package:cloud_firestore/cloud_firestore.dart';
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
    String? parseString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Timestamp) return v.toDate().toIso8601String();
      final typeStr = v.runtimeType.toString();
      if (typeStr.contains('FieldValue') || typeStr.contains('Sentinel') || typeStr.contains('minified')) {
        return DateTime.now().toIso8601String();
      }
      try {
        final res = (v as dynamic).toDate();
        if (res is DateTime) return res.toIso8601String();
      } catch (_) {}
      return v.toString();
    }

    List<String> parseStringList(dynamic v) {
      if (v == null || v is! Iterable) return [];
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    return SubGroupModel(
      id: id,
      branchId: parseString(data['branchId']) ?? 'default-branch',
      name: parseString(data['name']) ?? '',
      type: parseString(data['type']) ?? 'houseFellowship',
      recordingOfficerMemberId: parseString(data['recordingOfficerMemberId']) ?? parseString(data['officerMemberId']) ?? '',
      officerName: parseString(data['officerName']),
      memberIds: parseStringList(data['memberIds']),
      meetingDay: parseString(data['meetingDay']) ?? 'Sunday',
      meetingTime: parseString(data['meetingTime']) ?? '17:00',
      locationAddress: parseString(data['locationAddress']) ?? '',
      createdAt: parseString(data['createdAt']),
    );
  }

  SubGroupModel copyWith({
    String? id,
    String? branchId,
    String? name,
    String? type,
    String? recordingOfficerMemberId,
    String? officerName,
    List<String>? memberIds,
    String? meetingDay,
    String? meetingTime,
    String? locationAddress,
    String? createdAt,
  }) {
    return SubGroupModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      type: type ?? this.type,
      recordingOfficerMemberId: recordingOfficerMemberId ?? this.recordingOfficerMemberId,
      officerName: officerName ?? this.officerName,
      memberIds: memberIds ?? this.memberIds,
      meetingDay: meetingDay ?? this.meetingDay,
      meetingTime: meetingTime ?? this.meetingTime,
      locationAddress: locationAddress ?? this.locationAddress,
      createdAt: createdAt ?? this.createdAt,
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
