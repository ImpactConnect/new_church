import 'package:equatable/equatable.dart';

class BranchModel extends Equatable {
  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.pastorInCharge,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String address;
  final String pastorInCharge;
  final String phone;
  final DateTime createdAt;

  factory BranchModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BranchModel(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      pastorInCharge: data['pastorInCharge'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'address': address,
    'pastorInCharge': pastorInCharge,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  BranchModel copyWith({
    String? name,
    String? address,
    String? pastorInCharge,
    String? phone,
  }) => BranchModel(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    pastorInCharge: pastorInCharge ?? this.pastorInCharge,
    phone: phone ?? this.phone,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, name];
}
