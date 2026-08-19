import 'package:equatable/equatable.dart';

class BranchModel extends Equatable {
  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.pastorInCharge,
    required this.phone,
    required this.createdAt,
    this.pastorId,
    this.pastorEmail,
    this.city,
    this.state,
    this.active = true,
  });

  final String id;
  final String name;
  final String address;
  final String pastorInCharge;
  final String phone;
  final DateTime createdAt;
  final String? pastorId;
  final String? pastorEmail;
  final String? city;
  final String? state;
  final bool active;

  factory BranchModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BranchModel(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      pastorInCharge: data['pastorInCharge'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      pastorId: data['pastorId'] as String?,
      pastorEmail: data['pastorEmail'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      active: data['active'] as bool? ?? true,
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
    if (pastorId != null) 'pastorId': pastorId,
    if (pastorEmail != null) 'pastorEmail': pastorEmail,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };

  BranchModel copyWith({
    String? name,
    String? address,
    String? pastorInCharge,
    String? phone,
    String? pastorId,
    String? pastorEmail,
    String? city,
    String? state,
    bool? active,
  }) => BranchModel(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    pastorInCharge: pastorInCharge ?? this.pastorInCharge,
    phone: phone ?? this.phone,
    pastorId: pastorId ?? this.pastorId,
    pastorEmail: pastorEmail ?? this.pastorEmail,
    city: city ?? this.city,
    state: state ?? this.state,
    active: active ?? this.active,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, name, pastorId, active];
}

