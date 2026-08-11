import 'package:equatable/equatable.dart';

enum SyncAction { create, update, delete }

enum SyncStatus { pending, processing, failed, synced }

class SyncOutboxModel extends Equatable {
  const SyncOutboxModel({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String collection;
  final String documentId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final SyncStatus status;
  final int retryCount;
  final String? lastError;

  factory SyncOutboxModel.fromJson(Map<String, dynamic> json) {
    return SyncOutboxModel(
      id: json['id'] as String,
      collection: json['collection'] as String,
      documentId: json['documentId'] as String,
      action: SyncAction.values.byName(json['action'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: SyncStatus.values.byName(json['status'] as String? ?? 'pending'),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection': collection,
    'documentId': documentId,
    'action': action.name,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    if (lastError != null) 'lastError': lastError,
  };

  SyncOutboxModel copyWith({
    SyncStatus? status,
    int? retryCount,
    String? lastError,
  }) => SyncOutboxModel(
    id: id,
    collection: collection,
    documentId: documentId,
    action: action,
    payload: payload,
    timestamp: timestamp,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  List<Object?> get props => [id, collection, documentId, action, status, retryCount];
}
