import 'package:cms/src/features/roles/models/role_model.dart';

abstract class RoleRepository {
  Stream<List<RoleModel>> watchRoles(String branchId);
  Future<List<RoleModel>> getRoles(String branchId);
  Future<void> assignRole(String branchId, String memberId, String roleId);
  Future<void> removeRole(String branchId, String memberId);
  Future<void> seedRoles(String branchId);
}
