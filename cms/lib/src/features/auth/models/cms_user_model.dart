import 'package:equatable/equatable.dart';
import 'package:cms/src/core/permissions.dart';

/// Represents a signed-in CMS user with their role + branch context.
/// Custom claims from Firebase Auth token carry [branchId] and [roleId].
class CmsUserModel extends Equatable {
  const CmsUserModel({
    required this.uid,
    required this.email,
    required this.branchId,
    required this.roleId,
    required this.permissions,
    this.displayName,
  });

  final String uid;
  final String email;
  final String branchId;
  final String roleId;
  final List<String> permissions;
  final String? displayName;

  /// Check a single atomic permission.
  bool can(String permission) {
    if (permissions.contains(permission)) return true;
    final defaults = AppRole.defaultPermissions[roleId];
    if (defaults != null && defaults.contains(permission)) return true;
    return false;
  }

  /// Check if user holds any of the given permissions.
  bool canAny(List<String> perms) => perms.any(can);

  factory CmsUserModel.fromClaims({
    required String uid,
    required String email,
    required Map<String, dynamic> claims,
    required List<String> permissions,
    String? displayName,
  }) {
    return CmsUserModel(
      uid: uid,
      email: email,
      branchId: claims['branchId'] as String? ?? '',
      roleId: claims['roleId'] as String? ?? '',
      permissions: permissions,
      displayName: displayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'branchId': branchId,
        'roleId': roleId,
        'permissions': permissions,
        'displayName': displayName,
      };

  factory CmsUserModel.fromJson(Map<String, dynamic> json) => CmsUserModel(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        branchId: json['branchId'] as String? ?? 'default-branch',
        roleId: json['roleId'] as String? ?? '',
        permissions: List<String>.from(json['permissions'] ?? []),
        displayName: json['displayName'] as String?,
      );

  @override
  List<Object?> get props => [uid, email, branchId, roleId, permissions];
}
