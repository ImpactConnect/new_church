import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GroupIncomeRecordModel extends Equatable {
  const GroupIncomeRecordModel({
    required this.id,
    required this.branchId,
    required this.entityId,
    required this.entityName,
    required this.entityType, // 'department' | 'subGroup'
    required this.incomeCategory, // 'offering' | 'generalDonation' | 'projectDonation'
    required this.amount,
    required this.paymentMethod, // 'cash' | 'transfer' | 'cheque'
    required this.recordedBy,
    required this.date,
    this.projectName,
    this.donorMemberId,
    this.donorMemberName,
    this.notes,
  });

  final String id;
  final String branchId;
  final String entityId;
  final String entityName;
  final String entityType;
  final String incomeCategory;
  final double amount;
  final String paymentMethod;
  final String recordedBy;
  final DateTime date;
  final String? projectName;
  final String? donorMemberId;
  final String? donorMemberName;
  final String? notes;

  factory GroupIncomeRecordModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return GroupIncomeRecordModel(
      id: id,
      branchId: data['branchId'] as String? ?? 'default-branch',
      entityId: data['entityId'] as String? ?? '',
      entityName: data['entityName'] as String? ?? '',
      entityType: data['entityType'] as String? ?? 'department',
      incomeCategory: data['incomeCategory'] as String? ?? 'offering',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'cash',
      recordedBy: data['recordedBy'] as String? ?? '',
      date: parseDate(data['date']),
      projectName: data['projectName'] as String?,
      donorMemberId: data['donorMemberId'] as String?,
      donorMemberName: data['donorMemberName'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId,
        'entityId': entityId,
        'entityName': entityName,
        'entityType': entityType,
        'incomeCategory': incomeCategory,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'recordedBy': recordedBy,
        'date': date.toIso8601String(),
        if (projectName != null) 'projectName': projectName,
        if (donorMemberId != null) 'donorMemberId': donorMemberId,
        if (donorMemberName != null) 'donorMemberName': donorMemberName,
        if (notes != null) 'notes': notes,
      };

  String get categoryDisplayName => switch (incomeCategory) {
        'offering' => 'Meeting Offering',
        'generalDonation' => 'General Department Donation',
        'projectDonation' => 'Project Contribution',
        _ => 'Income',
      };

  @override
  List<Object?> get props => [
        id,
        branchId,
        entityId,
        entityType,
        incomeCategory,
        amount,
        projectName,
        donorMemberId,
        date,
      ];
}
