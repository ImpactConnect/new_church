import 'package:equatable/equatable.dart';

class DepartmentModel extends Equatable {
  const DepartmentModel({
    required this.id,
    required this.name,
    required this.departmentType,
    this.headMemberId,
    this.headMemberName,
    this.memberIds = const [],
  });

  final String id;
  final String name;
  final String departmentType; // 'Choir', 'Ushering', 'Welfare', 'Youth', etc.
  final String? headMemberId;
  final String? headMemberName; // denormalized for display
  final List<String> memberIds;

  factory DepartmentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DepartmentModel(
      id: id,
      name: data['name'] as String? ?? '',
      departmentType: data['departmentType'] as String? ?? '',
      headMemberId: data['headMemberId'] as String?,
      headMemberName: data['headMemberName'] as String?,
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'departmentType': departmentType,
    if (headMemberId != null) 'headMemberId': headMemberId,
    if (headMemberName != null) 'headMemberName': headMemberName,
    'memberIds': memberIds,
  };

  DepartmentModel copyWith({
    String? name,
    String? departmentType,
    String? headMemberId,
    String? headMemberName,
    List<String>? memberIds,
  }) => DepartmentModel(
    id: id,
    name: name ?? this.name,
    departmentType: departmentType ?? this.departmentType,
    headMemberId: headMemberId ?? this.headMemberId,
    headMemberName: headMemberName ?? this.headMemberName,
    memberIds: memberIds ?? this.memberIds,
  );

  @override
  List<Object?> get props => [id, name, departmentType];
}
