import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/departments/models/department_model.dart';
import 'package:cms/src/repositories/department_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseDepartmentRepository implements DepartmentRepository {
  FirebaseDepartmentRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('departments');

  @override
  Stream<List<DepartmentModel>> watchDepartments(String branchId) =>
      _col(branchId).orderBy('name').snapshots().map(
        (s) => s.docs
            .map((d) => DepartmentModel.fromFirestore(d.data(), d.id))
            .toList(),
      );

  @override
  Future<void> saveDepartment(String branchId, DepartmentModel dept) async {
    final id = dept.id.isEmpty ? _uuid.v4() : dept.id;
    await _col(branchId).doc(id).set(dept.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteDepartment(String branchId, String deptId) async {
    await _col(branchId).doc(deptId).delete();
  }

  @override
  Future<void> addMemberToDepartment(
    String branchId,
    String deptId,
    String memberId,
  ) async {
    await _col(branchId).doc(deptId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
    });
    // Also update member's departmentIds array
    await _db
        .collection('branches')
        .doc(branchId)
        .collection('members')
        .doc(memberId)
        .update({'departmentIds': FieldValue.arrayUnion([deptId])});
  }

  @override
  Future<void> removeMemberFromDepartment(
    String branchId,
    String deptId,
    String memberId,
  ) async {
    await _col(branchId).doc(deptId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
    });
    await _db
        .collection('branches')
        .doc(branchId)
        .collection('members')
        .doc(memberId)
        .update({'departmentIds': FieldValue.arrayRemove([deptId])});
  }
}
