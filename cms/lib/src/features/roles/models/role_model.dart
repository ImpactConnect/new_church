import 'package:equatable/equatable.dart';

class RoleModel extends Equatable {
  const RoleModel({
    required this.id,
    required this.name,
    required this.permissions,
    this.scopeType,
    this.scopeDepartmentId,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final List<String> permissions;
  final String? scopeType; // 'branch' | 'department'
  final String? scopeDepartmentId;

  final bool isCustom;

  bool get isSystemRole => id == 'leadPastor' || id == 'secretary' || id == 'financeDept' || id == 'branchPastor';

  factory RoleModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RoleModel(
      id: id,
      name: data['name'] as String? ?? id,
      permissions: List<String>.from(data['permissions'] ?? []),
      scopeType: data['scope']?['type'] as String?,
      scopeDepartmentId: data['scope']?['departmentId'] as String?,
      isCustom: data['isCustom'] as bool? ?? (id != 'leadPastor' && id != 'secretary' && id != 'financeDept' && id != 'branchPastor'),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'permissions': permissions,
    'isCustom': isCustom,
    'scope': {
      if (scopeType != null) 'type': scopeType,
      if (scopeDepartmentId != null) 'departmentId': scopeDepartmentId,
    },
  };

  String get displayName => switch (id) {
    'leadPastor' => 'Lead Pastor',
    'secretary' => 'Secretary',
    'financeDept' => 'Finance Dept',
    'branchPastor' => 'Branch Pastor',
    _ => name,
  };

  @override
  List<Object?> get props => [id, name, permissions, isCustom];
}
