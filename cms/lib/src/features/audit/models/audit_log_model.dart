import 'package:equatable/equatable.dart';

class AuditLogModel extends Equatable {
  const AuditLogModel({
    required this.id,
    required this.module,
    required this.documentId,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.timestamp,
    this.before,
    this.after,
  });

  final String id;
  final String module; // 'members' | 'departments' | 'roles' | 'budgets' | etc.
  final String documentId;
  final String action; // 'create' | 'update' | 'delete' | 'approve' | 'reject'
  final String performedBy;
  final String performedByName;
  final DateTime timestamp;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  factory AuditLogModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AuditLogModel(
      id: id,
      module: data['module'] as String? ?? '',
      documentId: data['documentId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      performedBy: data['performedBy'] as String? ?? '',
      performedByName: data['performedByName'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      before: data['before'] as Map<String, dynamic>?,
      after: data['after'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [id, module, action, timestamp];
}
