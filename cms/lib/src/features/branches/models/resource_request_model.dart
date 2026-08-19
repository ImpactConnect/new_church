import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A resource request from a branch pastor to the head church.
class ResourceRequestModel extends Equatable {
  const ResourceRequestModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.requestedBy,
    required this.requestedByName,
    required this.itemDescription,
    required this.category,
    required this.quantity,
    required this.urgency,        // 'low' | 'medium' | 'high'
    required this.status,         // 'pending' | 'approved' | 'rejected' | 'fulfilled'
    this.estimatedCost,
    this.justification,
    this.neededBy,
    this.respondedBy,
    this.respondedAt,
    this.responseNote,
    this.fulfilledAt,
    this.createdAt,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String requestedBy;
  final String requestedByName;
  final String itemDescription;
  final String category;    // 'equipment' | 'materials' | 'vehicle' | 'furniture' | 'other'
  final int quantity;
  final String urgency;
  final String status;
  final double? estimatedCost;
  final String? justification;
  final DateTime? neededBy;
  final String? respondedBy;
  final DateTime? respondedAt;
  final String? responseNote;
  final DateTime? fulfilledAt;
  final DateTime? createdAt;

  factory ResourceRequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateOpt(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return ResourceRequestModel(
      id: id,
      branchId: data['branchId'] as String? ?? '',
      branchName: data['branchName'] as String? ?? '',
      requestedBy: data['requestedBy'] as String? ?? '',
      requestedByName: data['requestedByName'] as String? ?? '',
      itemDescription: data['itemDescription'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      urgency: data['urgency'] as String? ?? 'medium',
      status: data['status'] as String? ?? 'pending',
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble(),
      justification: data['justification'] as String?,
      neededBy: parseDateOpt(data['neededBy']),
      respondedBy: data['respondedBy'] as String?,
      respondedAt: parseDateOpt(data['respondedAt']),
      responseNote: data['responseNote'] as String?,
      fulfilledAt: parseDateOpt(data['fulfilledAt']),
      createdAt: parseDateOpt(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId,
        'branchName': branchName,
        'requestedBy': requestedBy,
        'requestedByName': requestedByName,
        'itemDescription': itemDescription,
        'category': category,
        'quantity': quantity,
        'urgency': urgency,
        'status': status,
        if (estimatedCost != null) 'estimatedCost': estimatedCost,
        if (justification != null) 'justification': justification,
        if (neededBy != null) 'neededBy': Timestamp.fromDate(neededBy!),
        if (respondedBy != null) 'respondedBy': respondedBy,
        if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
        if (responseNote != null) 'responseNote': responseNote,
        if (fulfilledAt != null) 'fulfilledAt': Timestamp.fromDate(fulfilledAt!),
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [id, branchId, itemDescription, status, urgency];
}
