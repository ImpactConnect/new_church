import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  const AssetModel({
    required this.id,
    required this.name,
    required this.category, // 'Electronics & Media', 'Instruments & Sound', 'Furniture & Fixtures', 'Vehicles', 'Real Estate & Buildings', 'Office Equipment'
    required this.condition, // 'Excellent', 'Good', 'Fair', 'Poor', 'Under Maintenance'
    required this.location,
    this.tagId,
    this.serialNumber,
    this.vendor,
    this.purchaseDate,
    this.lastMaintenanceDate,
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
  final String? tagId;
  final String? serialNumber;
  final String? vendor;
  final DateTime? purchaseDate;
  final DateTime? lastMaintenanceDate;
  final double purchaseCost;
  final double currentBookValue;
  final String? assignedDepartmentId;
  final String? notes;

  factory AssetModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AssetModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Furniture & Fixtures',
      condition: data['condition'] as String? ?? 'Good',
      location: data['location'] as String? ?? '',
      tagId: data['tagId'] as String?,
      serialNumber: data['serialNumber'] as String?,
      vendor: data['vendor'] as String?,
      purchaseDate: data['purchaseDate'] != null
          ? DateTime.tryParse(data['purchaseDate'].toString())
          : null,
      lastMaintenanceDate: data['lastMaintenanceDate'] != null
          ? DateTime.tryParse(data['lastMaintenanceDate'].toString())
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
    if (tagId != null) 'tagId': tagId,
    if (serialNumber != null) 'serialNumber': serialNumber,
    if (vendor != null) 'vendor': vendor,
    if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
    if (lastMaintenanceDate != null) 'lastMaintenanceDate': lastMaintenanceDate!.toIso8601String(),
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
    String? tagId,
    String? serialNumber,
    String? vendor,
    DateTime? purchaseDate,
    DateTime? lastMaintenanceDate,
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
    tagId: tagId ?? this.tagId,
    serialNumber: serialNumber ?? this.serialNumber,
    vendor: vendor ?? this.vendor,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
    purchaseCost: purchaseCost ?? this.purchaseCost,
    currentBookValue: currentBookValue ?? this.currentBookValue,
    assignedDepartmentId: assignedDepartmentId ?? this.assignedDepartmentId,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [id, name, category, condition, location, purchaseCost];
}
