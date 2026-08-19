import 'package:cms/src/features/roles/models/role_model.dart';

abstract class RoleRepository {
  Stream<List<RoleModel>> watchRoles(String branchId);
  Future<List<RoleModel>> getRoles(String branchId);
  Future<void> assignRole(String branchId, String memberId, String roleId);
  Future<void> removeRole(String branchId, String memberId);
  Future<void> seedRoles(String branchId);
  Future<void> createCustomRole(String branchId, String name, List<String> permissions);
  Future<void> updateCustomRole(String branchId, String roleId, String name, List<String> permissions);
  Future<void> deleteCustomRole(String branchId, String roleId);
  Future<void> provisionStaffAccount({
    required String branchId,
    required String name,
    required String email,
    required String password,
    required String roleId,
    String? phone,
  });
}
