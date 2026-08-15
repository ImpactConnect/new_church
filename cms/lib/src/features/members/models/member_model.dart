import 'package:equatable/equatable.dart';

/// Represents a relationship between this member and another church member.
class MemberRelation extends Equatable {
  const MemberRelation({
    required this.memberId,
    required this.memberName,
    required this.relationship,
    this.customRelationship,
  });

  final String memberId;
  final String memberName; // denormalized for display
  final String relationship; // Wife, Husband, Son, Daughter, Cousin, Grandparent, Sibling, Friend, Other
  final String? customRelationship; // filled when relationship == 'Other'

  String get displayRelationship =>
      relationship == 'Other' && customRelationship != null && customRelationship!.isNotEmpty
          ? customRelationship!
          : relationship;

  factory MemberRelation.fromMap(Map<String, dynamic> data) {
    return MemberRelation(
      memberId: data['memberId'] as String? ?? '',
      memberName: data['memberName'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      customRelationship: data['customRelationship'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'memberName': memberName,
    'relationship': relationship,
    if (customRelationship != null) 'customRelationship': customRelationship,
  };

  @override
  List<Object?> get props => [memberId, relationship];
}

class MemberModel extends Equatable {
  const MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.gender,
    required this.joinDate,
    required this.memberStatus,
    this.email,
    this.dob,
    this.maritalStatus,
    this.departmentIds = const [],
    this.roleId,
    this.importBatchId,
    this.importedAt,
    this.profileImageUrl,
    this.relations = const [],
    this.residentAddress,
    this.profession,
    this.weddingDate,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String gender; // 'male' | 'female'
  final DateTime joinDate;
  final String memberStatus; // 'active' | 'inactive' | 'transferred'
  final DateTime? dob;
  final String? maritalStatus;
  final List<String> departmentIds;
  final String? roleId;
  final String? importBatchId;
  final DateTime? importedAt;
  final String? profileImageUrl;
  final List<MemberRelation> relations;
  final String? residentAddress;
  final String? profession;
  final DateTime? weddingDate;

  String get fullName => '$firstName $lastName';

  factory MemberModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MemberModel(
      id: id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      gender: data['gender'] as String? ?? '',
      joinDate: _parseDate(data['joinDate']) ?? DateTime.now(),
      memberStatus: data['memberStatus'] as String? ?? 'active',
      dob: _parseDate(data['dob']),
      maritalStatus: data['maritalStatus'] as String?,
      departmentIds: List<String>.from(data['departmentIds'] ?? []),
      roleId: data['roleId'] as String?,
      importBatchId: data['importBatchId'] as String?,
      importedAt: _parseDate(data['importedAt']),
      profileImageUrl: data['profileImageUrl'] as String?,
      relations: (data['relations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MemberRelation.fromMap)
          .toList(),
      residentAddress: data['residentAddress'] as String?,
      profession: data['profession'] as String?,
      weddingDate: _parseDate(data['weddingDate']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    if (email != null) 'email': email,
    'gender': gender,
    'joinDate': joinDate.toIso8601String(),
    'memberStatus': memberStatus,
    if (dob != null) 'dob': dob!.toIso8601String(),
    if (maritalStatus != null) 'maritalStatus': maritalStatus,
    'departmentIds': departmentIds,
    if (roleId != null) 'roleId': roleId,
    if (importBatchId != null) 'importBatchId': importBatchId,
    if (importedAt != null) 'importedAt': importedAt!.toIso8601String(),
    if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    'relations': relations.map((r) => r.toMap()).toList(),
    if (residentAddress != null) 'residentAddress': residentAddress,
    if (profession != null) 'profession': profession,
    if (weddingDate != null) 'weddingDate': weddingDate!.toIso8601String(),
  };

  MemberModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? gender,
    DateTime? joinDate,
    String? memberStatus,
    DateTime? dob,
    String? maritalStatus,
    List<String>? departmentIds,
    String? roleId,
    String? profileImageUrl,
    List<MemberRelation>? relations,
    String? residentAddress,
    String? profession,
    DateTime? weddingDate,
  }) {
    return MemberModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      joinDate: joinDate ?? this.joinDate,
      memberStatus: memberStatus ?? this.memberStatus,
      dob: dob ?? this.dob,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      departmentIds: departmentIds ?? this.departmentIds,
      roleId: roleId ?? this.roleId,
      importBatchId: importBatchId,
      importedAt: importedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      relations: relations ?? this.relations,
      residentAddress: residentAddress ?? this.residentAddress,
      profession: profession ?? this.profession,
      weddingDate: weddingDate ?? this.weddingDate,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate();
    }
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [id, firstName, lastName, phone, memberStatus];
}
