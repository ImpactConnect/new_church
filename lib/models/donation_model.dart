import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String title;
  final String description;
  final bool isFixedAmount;
  final double? fixedAmount;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? paystackLink;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  DonationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isFixedAmount,
    this.fixedAmount,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.paystackLink,
    this.imageUrl,
    required this.sortOrder,
    this.isActive = true,
  });

  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isFixedAmount: data['isFixedAmount'] ?? false,
      fixedAmount: (data['fixedAmount'] as num?)?.toDouble(),
      bankName: data['bankName'],
      accountName: data['accountName'],
      accountNumber: data['accountNumber'],
      paystackLink: data['paystackLink'],
      imageUrl: data['imageUrl'],
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isFixedAmount': isFixedAmount,
      'fixedAmount': fixedAmount,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'paystackLink': paystackLink,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
