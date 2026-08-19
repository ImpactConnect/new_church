import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  const BudgetModel({
    required this.id,
    required this.fiscalPeriod,
    required this.category,
    required this.requestedAmount,
    required this.status,
    required this.requestedBy,
    this.departmentId,
    this.requestedDescription,
    this.approvedAmount,
    this.approvedCategory,
    this.approvedDescription,
    this.approvedBy,
    this.approvedAt,
    this.changesSummary = const [],
    this.rejectionReason,
  });

  final String id;
  final String fiscalPeriod;
  final String category;
  final double requestedAmount;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String requestedBy;
  final String? departmentId;
  final String? requestedDescription;
  final double? approvedAmount;
  final String? approvedCategory;
  final String? approvedDescription;
  final String? approvedBy;
  final DateTime? approvedAt;
  final List<Map<String, dynamic>> changesSummary;
  final String? rejectionReason;

  factory BudgetModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return BudgetModel(
      id: id,
      fiscalPeriod: data['fiscalPeriod'] as String? ?? '',
      category: data['category'] as String? ?? '',
      requestedAmount: (data['requestedAmount'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      requestedBy: data['requestedBy'] as String? ?? '',
      departmentId: data['departmentId'] as String?,
      requestedDescription: data['requestedDescription'] as String?,
      approvedAmount: (data['approvedAmount'] as num?)?.toDouble(),
      approvedCategory: data['approvedCategory'] as String?,
      approvedDescription: data['approvedDescription'] as String?,
      approvedBy: data['approvedBy'] as String?,
      approvedAt: parseDate(data['approvedAt']),
      changesSummary: List<Map<String, dynamic>>.from(
        data['changesSummary'] ?? [],
      ),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fiscalPeriod': fiscalPeriod,
    'category': category,
    'requestedAmount': requestedAmount,
    'status': status,
    'requestedBy': requestedBy,
    if (departmentId != null) 'departmentId': departmentId,
    if (requestedDescription != null) 'requestedDescription': requestedDescription,
    if (approvedAmount != null) 'approvedAmount': approvedAmount,
    if (approvedCategory != null) 'approvedCategory': approvedCategory,
    if (approvedDescription != null) 'approvedDescription': approvedDescription,
    if (approvedBy != null) 'approvedBy': approvedBy,
    if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
    'changesSummary': changesSummary,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };

  @override
  List<Object?> get props => [id, status, requestedAmount, approvedAmount];
}

class ExpenditureRequestModel extends Equatable {
  const ExpenditureRequestModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.requestedBy,
    required this.status,
    this.originalAmount,
    this.originalCategory,
    this.originalDescription,
    this.approvedAmount,
    this.approvedCategory,
    this.approvedDescription,
    this.changesSummary = const [],
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  final String id;
  final double amount;
  final String category;
  final String description;
  final String requestedBy;
  final String status;
  final double? originalAmount;
  final String? originalCategory;
  final String? originalDescription;
  final double? approvedAmount;
  final String? approvedCategory;
  final String? approvedDescription;
  final List<Map<String, dynamic>> changesSummary;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  factory ExpenditureRequestModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return ExpenditureRequestModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      requestedBy: data['requestedBy'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      originalAmount: (data['originalAmount'] as num?)?.toDouble(),
      originalCategory: data['originalCategory'] as String?,
      originalDescription: data['originalDescription'] as String?,
      approvedAmount: (data['approvedAmount'] as num?)?.toDouble(),
      approvedCategory: data['approvedCategory'] as String?,
      approvedDescription: data['approvedDescription'] as String?,
      changesSummary: List<Map<String, dynamic>>.from(
        data['changesSummary'] ?? [],
      ),
      approvedBy: data['approvedBy'] as String?,
      approvedAt: parseDate(data['approvedAt']),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'amount': amount,
    'category': category,
    'description': description,
    'requestedBy': requestedBy,
    'status': status,
    if (originalAmount != null) 'originalAmount': originalAmount,
    if (originalCategory != null) 'originalCategory': originalCategory,
    if (originalDescription != null) 'originalDescription': originalDescription,
    if (approvedAmount != null) 'approvedAmount': approvedAmount,
    if (approvedCategory != null) 'approvedCategory': approvedCategory,
    if (approvedDescription != null) 'approvedDescription': approvedDescription,
    'changesSummary': changesSummary,
    if (approvedBy != null) 'approvedBy': approvedBy,
    if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };

  @override
  List<Object?> get props => [id, status, amount, approvedAmount];
}

class ExpenditureModel extends Equatable {
  const ExpenditureModel({
    required this.id,
    required this.approvedAmount,
    required this.category,
    required this.description,
    required this.approvedBy,
    required this.sourceRequestId,
    required this.date,
    required this.totalDisbursed,
    required this.status,
  });

  final String id;
  final double approvedAmount;
  final String category;
  final String description;
  final String approvedBy;
  final String sourceRequestId;
  final DateTime date;
  final double totalDisbursed;
  final String status; // 'not-disbursed' | 'partially-disbursed' | 'fully-disbursed'

  double get remainingBalance => approvedAmount - totalDisbursed;

  factory ExpenditureModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ExpenditureModel(
      id: id,
      approvedAmount: (data['approvedAmount'] as num?)?.toDouble() ?? 0,
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      approvedBy: data['approvedBy'] as String? ?? '',
      sourceRequestId: data['sourceRequestId'] as String? ?? '',
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalDisbursed: (data['totalDisbursed'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'not-disbursed',
    );
  }

  @override
  List<Object?> get props => [id, status, approvedAmount, totalDisbursed];
}

class DisbursementModel extends Equatable {
  const DisbursementModel({
    required this.id,
    required this.amountDisbursed,
    required this.date,
    required this.recipientName,
    required this.purpose,
    required this.disbursedBy,
    this.receiptUrl,
  });

  final String id;
  final double amountDisbursed;
  final DateTime date;
  final String recipientName;
  final String purpose;
  final String disbursedBy;
  final String? receiptUrl;

  factory DisbursementModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return DisbursementModel(
      id: id,
      amountDisbursed: (data['amountDisbursed'] as num?)?.toDouble() ?? 0,
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recipientName: data['recipientName'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      disbursedBy: data['disbursedBy'] as String? ?? '',
      receiptUrl: data['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'amountDisbursed': amountDisbursed,
    'date': date.toIso8601String(),
    'recipientName': recipientName,
    'purpose': purpose,
    'disbursedBy': disbursedBy,
    if (receiptUrl != null) 'receiptUrl': receiptUrl,
  };

  @override
  List<Object?> get props => [id, amountDisbursed, recipientName];
}

class IncomeModel extends Equatable {
  const IncomeModel({
    required this.id,
    required this.amount,
    required this.source,
    required this.formType,
    required this.recordedBy,
    required this.date,
    this.comment,
  });

  final String id;
  final double amount;
  final String source;
  final String formType; // 'cash' | 'transfer' | 'cheque' | 'in-kind'
  final String recordedBy;
  final DateTime date;
  final String? comment;

  factory IncomeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return IncomeModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      source: data['source'] as String? ?? '',
      formType: data['formType'] as String? ?? 'cash',
      recordedBy: data['recordedBy'] as String? ?? '',
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      comment: data['comment'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'amount': amount,
    'source': source,
    'formType': formType,
    'recordedBy': recordedBy,
    'date': date.toIso8601String(),
    if (comment != null) 'comment': comment,
  };

  @override
  List<Object?> get props => [id, amount, source, formType];
}

class GivingModel extends Equatable {
  const GivingModel({
    required this.id,
    required this.memberId,
    required this.type,
    required this.amount,
    required this.date,
    required this.recordedBy,
  });

  final String id;
  final String memberId;
  final String type; // 'tithe' | 'offering' | 'pledge'
  final double amount;
  final DateTime date;
  final String recordedBy;

  factory GivingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GivingModel(
      id: id,
      memberId: data['memberId'] as String? ?? '',
      type: data['type'] as String? ?? 'offering',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'memberId': memberId,
    'type': type,
    'amount': amount,
    'date': date.toIso8601String(),
    'recordedBy': recordedBy,
  };

  @override
  List<Object?> get props => [id, memberId, type, amount];
}

/// Notification model — created when a budget/expenditure is approved/rejected.
/// Path: /branches/{branchId}/financeNotifications/{notificationId}
class FinanceNotificationModel extends Equatable {
  const FinanceNotificationModel({
    required this.id,
    required this.recipientUid,
    required this.type,
    required this.referenceId,
    required this.message,
    required this.createdAt,
    this.changesSummary = const [],
    this.read = false,
  });

  final String id;
  final String recipientUid;

  /// 'budget-approved' | 'budget-approved-with-changes' | 'budget-rejected'
  /// | 'expenditure-approved' | 'expenditure-approved-with-changes' | 'expenditure-rejected'
  final String type;
  final String referenceId;  // budgetId or requestId
  final String message;
  final List<Map<String, dynamic>> changesSummary;
  final bool read;
  final DateTime createdAt;

  factory FinanceNotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return FinanceNotificationModel(
      id: id,
      recipientUid: data['recipientUid'] as String? ?? '',
      type: data['type'] as String? ?? '',
      referenceId: data['referenceId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      changesSummary: List<Map<String, dynamic>>.from(
        data['changesSummary'] ?? [],
      ),
      read: data['read'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'recipientUid': recipientUid,
    'type': type,
    'referenceId': referenceId,
    'message': message,
    'changesSummary': changesSummary,
    'read': read,
    'createdAt': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, type, referenceId, read];
}
