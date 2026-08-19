import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A remittance record — branch pastor submits income sent to HQ finance dept.
class RemittanceModel extends Equatable {
  const RemittanceModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.amount,
    required this.currency,
    required this.remittanceDate,
    required this.submittedBy,
    required this.submittedByName,
    required this.period,        // e.g. "August 2026"
    required this.status,        // 'pending' | 'acknowledged' | 'queried'
    this.description,
    this.paymentMethod,          // 'bank_transfer' | 'cash' | 'cheque'
    this.referenceNumber,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.queryNote,
    this.createdAt,
  });

  final String id;
  final String branchId;
  final String branchName;
  final double amount;
  final String currency;
  final DateTime remittanceDate;
  final String submittedBy;
  final String submittedByName;
  final String period;
  final String status;
  final String? description;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? queryNote;
  final DateTime? createdAt;

  factory RemittanceModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic v, [DateTime? fallback]) {
      if (v == null) return fallback ?? DateTime.now();
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString()) ?? fallback ?? DateTime.now();
    }
    DateTime? parseDateOpt(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return RemittanceModel(
      id: id,
      branchId: data['branchId'] as String? ?? '',
      branchName: data['branchName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'NGN',
      remittanceDate: parseDate(data['remittanceDate']),
      submittedBy: data['submittedBy'] as String? ?? '',
      submittedByName: data['submittedByName'] as String? ?? '',
      period: data['period'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      referenceNumber: data['referenceNumber'] as String?,
      acknowledgedBy: data['acknowledgedBy'] as String?,
      acknowledgedAt: parseDateOpt(data['acknowledgedAt']),
      queryNote: data['queryNote'] as String?,
      createdAt: parseDateOpt(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId,
        'branchName': branchName,
        'amount': amount,
        'currency': currency,
        'remittanceDate': Timestamp.fromDate(remittanceDate),
        'submittedBy': submittedBy,
        'submittedByName': submittedByName,
        'period': period,
        'status': status,
        if (description != null) 'description': description,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (referenceNumber != null) 'referenceNumber': referenceNumber,
        if (acknowledgedBy != null) 'acknowledgedBy': acknowledgedBy,
        if (acknowledgedAt != null) 'acknowledgedAt': Timestamp.fromDate(acknowledgedAt!),
        if (queryNote != null) 'queryNote': queryNote,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [id, branchId, amount, period, status];
}
