import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/audit/models/audit_log_model.dart';
import 'package:cms/src/repositories/audit_log_repository.dart';

class FirebaseAuditLogRepository implements AuditLogRepository {
  FirebaseAuditLogRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;

  @override
  Stream<List<AuditLogModel>> watchAuditLogs(
    String branchId, {
    String? module,
    String? performedBy,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('branches')
        .doc(branchId)
        .collection('auditLogs')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (module != null) {
      query = query.where('module', isEqualTo: module);
    }
    if (performedBy != null) {
      query = query.where('performedBy', isEqualTo: performedBy);
    }

    return query.snapshots().map(
      (s) => s.docs
          .map((d) => AuditLogModel.fromFirestore(d.data(), d.id))
          .toList(),
    );
  }
}
