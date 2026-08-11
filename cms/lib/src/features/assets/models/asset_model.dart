import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  const AssetModel({
    required this.id,
    required this.name,
    required this.category, // 'Electronics', 'Instruments', 'Furniture', 'Vehicles', 'Real Estate'
    required this.condition, // 'Excellent', 'Good', 'Fair', 'Poor'
    required this.location,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost = 0.0,
    this.currentBookValue = 0.0,
    this.assignedDepartmentId,
    this.notes,
  });

  final String id;
  final String name;
  final String category;
  final String condition;
  final String location;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double purchaseCost;
  final double currentBookValue;
  final String? assignedDepartmentId;
  final String? notes;

  factory AssetModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AssetModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Furniture',
      condition: data['condition'] as String? ?? 'Good',
      location: data['location'] as String? ?? '',
      serialNumber: data['serialNumber'] as String?,
      purchaseDate: data['purchaseDate'] != null
          ? DateTime.tryParse(data['purchaseDate'].toString())
          : null,
      purchaseCost: (data['purchaseCost'] as num?)?.toDouble() ?? 0.0,
      currentBookValue: (data['currentBookValue'] as num?)?.toDouble() ?? 0.0,
      assignedDepartmentId: data['assignedDepartmentId'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'category': category,
    'condition': condition,
    'location': location,
    if (serialNumber != null) 'serialNumber': serialNumber,
    if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
    'purchaseCost': purchaseCost,
    'currentBookValue': currentBookValue,
    if (assignedDepartmentId != null) 'assignedDepartmentId': assignedDepartmentId,
    if (notes != null) 'notes': notes,
  };

  AssetModel copyWith({
    String? name,
    String? category,
    String? condition,
    String? location,
    String? serialNumber,
    DateTime? purchaseDate,
    double? purchaseCost,
    double? currentBookValue,
    String? assignedDepartmentId,
    String? notes,
  }) => AssetModel(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    condition: condition ?? this.condition,
    location: location ?? this.location,
    serialNumber: serialNumber ?? this.serialNumber,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    purchaseCost: purchaseCost ?? this.purchaseCost,
    currentBookValue: currentBookValue ?? this.currentBookValue,
    assignedDepartmentId: assignedDepartmentId ?? this.assignedDepartmentId,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [id, name, category, condition, purchaseCost];
}
