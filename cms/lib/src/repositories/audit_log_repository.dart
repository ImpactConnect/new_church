import 'package:cms/src/features/audit/models/audit_log_model.dart';

abstract class AuditLogRepository {
  /// Stream audit logs for a branch, optionally filtered by module or uid.
  Stream<List<AuditLogModel>> watchAuditLogs(
    String branchId, {
    String? module,
    String? performedBy,
    int limit,
  });
}
