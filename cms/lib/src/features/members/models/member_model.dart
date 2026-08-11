import 'package:equatable/equatable.dart';

class MemberModel extends Equatable {
  const MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.gender,
    required this.joinDate,
    required this.memberStatus,
    this.dob,
    this.maritalStatus,
    this.departmentIds = const [],
    this.roleId,
    this.importBatchId,
    this.importedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String gender; // 'male' | 'female'
  final DateTime joinDate;
  final String memberStatus; // 'active' | 'inactive' | 'transferred'
  final DateTime? dob;
  final String? maritalStatus;
  final List<String> departmentIds;
  final String? roleId;
  final String? importBatchId;
  final DateTime? importedAt;

  String get fullName => '$firstName $lastName';

  factory MemberModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MemberModel(
      id: id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      joinDate: _parseDate(data['joinDate']) ?? DateTime.now(),
      memberStatus: data['memberStatus'] as String? ?? 'active',
      dob: _parseDate(data['dob']),
      maritalStatus: data['maritalStatus'] as String?,
      departmentIds: List<String>.from(data['departmentIds'] ?? []),
      roleId: data['roleId'] as String?,
      importBatchId: data['importBatchId'] as String?,
      importedAt: _parseDate(data['importedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'gender': gender,
    'joinDate': joinDate.toIso8601String(),
    'memberStatus': memberStatus,
    if (dob != null) 'dob': dob!.toIso8601String(),
    if (maritalStatus != null) 'maritalStatus': maritalStatus,
    'departmentIds': departmentIds,
    if (roleId != null) 'roleId': roleId,
    if (importBatchId != null) 'importBatchId': importBatchId,
    if (importedAt != null) 'importedAt': importedAt!.toIso8601String(),
  };

  MemberModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? gender,
    DateTime? joinDate,
    String? memberStatus,
    DateTime? dob,
    String? maritalStatus,
    List<String>? departmentIds,
    String? roleId,
  }) {
    return MemberModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      joinDate: joinDate ?? this.joinDate,
      memberStatus: memberStatus ?? this.memberStatus,
      dob: dob ?? this.dob,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      departmentIds: departmentIds ?? this.departmentIds,
      roleId: roleId ?? this.roleId,
      importBatchId: importBatchId,
      importedAt: importedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [id, firstName, lastName, phone, memberStatus];
}
