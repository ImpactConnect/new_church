import 'package:cms/src/features/departments/models/department_model.dart';

abstract class DepartmentRepository {
  Stream<List<DepartmentModel>> watchDepartments(String branchId);
  Future<void> saveDepartment(String branchId, DepartmentModel dept);
  Future<void> deleteDepartment(String branchId, String deptId);
  Future<void> addMemberToDepartment(String branchId, String deptId, String memberId);
  Future<void> removeMemberFromDepartment(String branchId, String deptId, String memberId);
}
