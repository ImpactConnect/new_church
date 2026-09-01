import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/assets/models/asset_model.dart';
import 'package:cms/src/repositories/asset_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseAssetRepository implements AssetRepository {
  FirebaseAssetRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('assets');

  @override
  Stream<List<AssetModel>> watchAssets(String branchId) {
    return _col(branchId).snapshots().asyncMap((s) async {
      if (s.docs.isEmpty) {
        await seedSampleAssets(branchId);
        final freshSnap = await _col(branchId).get();
        final items = freshSnap.docs.map((d) => AssetModel.fromFirestore(d.data(), d.id)).toList();
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      }
      final items = s.docs.map((d) => AssetModel.fromFirestore(d.data(), d.id)).toList();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    });
  }

  @override
  Future<void> saveAsset(String branchId, AssetModel asset) async {
    final id = asset.id.isEmpty ? _uuid.v4() : asset.id;
    await _col(branchId).doc(id).set(asset.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteAsset(String branchId, String assetId) async {
    await _col(branchId).doc(assetId).delete();
  }

  @override
  Future<void> seedSampleAssets(String branchId) async {
    final batch = _db.batch();
    final colRef = _col(branchId);

    final samples = [
      AssetModel(
        id: 'asset-sound-01',
        name: 'Behringer X32 Digital 40-Input Mixing Console',
        category: 'Instruments & Sound',
        condition: 'Excellent',
        location: 'Main Auditorium - Sound Booth',
        tagId: 'AUD-SND-001',
        serialNumber: 'BX32-98421-NG',
        vendor: 'ProSound Electronics Ikeja',
        purchaseDate: DateTime(2023, 4, 15),
        lastMaintenanceDate: DateTime(2024, 1, 10),
        purchaseCost: 3800000.0,
        currentBookValue: 3200000.0,
        assignedDepartmentId: 'Media & Technical',
        notes: 'Main FOH audio console. Serviced quarterly.',
      ),
      AssetModel(
        id: 'asset-sound-02',
        name: 'Yamaha PSR-SX900 Arranger Keyboard',
        category: 'Instruments & Sound',
        condition: 'Excellent',
        location: 'Sanctuary Stage',
        tagId: 'AUD-SND-002',
        serialNumber: 'YMH-SX900-334',
        vendor: 'Musician’s Haven Victoria Island',
        purchaseDate: DateTime(2023, 8, 20),
        lastMaintenanceDate: DateTime(2024, 2, 1),
        purchaseCost: 2400000.0,
        currentBookValue: 2100000.0,
        assignedDepartmentId: 'Choir & Music',
        notes: 'Primary keyboard for main services.',
      ),
      AssetModel(
        id: 'asset-sound-03',
        name: 'Yamaha C3 Conservatory Studio Grand Piano',
        category: 'Instruments & Sound',
        condition: 'Good',
        location: 'Sanctuary Stage',
        tagId: 'AUD-SND-003',
        serialNumber: 'YMH-C3GP-8891',
        vendor: 'Steinway & Sons West Africa',
        purchaseDate: DateTime(2021, 11, 5),
        lastMaintenanceDate: DateTime(2023, 11, 20),
        purchaseCost: 12500000.0,
        currentBookValue: 10800000.0,
        assignedDepartmentId: 'Choir & Music',
        notes: 'Acoustic piano tuned every 6 months.',
      ),
      AssetModel(
        id: 'asset-media-01',
        name: 'Canon XA40 Professional 4K Camcorder (Set of 3)',
        category: 'Electronics & Media',
        condition: 'Excellent',
        location: 'Media Booth & Camera Rigs',
        tagId: 'AUD-MED-001',
        serialNumber: 'CN-XA40-TRIPLET',
        vendor: 'Konga B2B Corporate',
        purchaseDate: DateTime(2023, 6, 12),
        lastMaintenanceDate: DateTime(2024, 1, 15),
        purchaseCost: 4600000.0,
        currentBookValue: 4000000.0,
        assignedDepartmentId: 'Media & Technical',
        notes: 'Includes SDI cables and heavy-duty tripods.',
      ),
      AssetModel(
        id: 'asset-media-02',
        name: 'Epson Pro L1505UH 12,000-Lumen 4K Laser Projector',
        category: 'Electronics & Media',
        condition: 'Good',
        location: 'Auditorium Ceiling Mount',
        tagId: 'AUD-MED-002',
        serialNumber: 'EPS-L1505-99',
        vendor: 'VisualTech Solutions Lagos',
        purchaseDate: DateTime(2022, 9, 10),
        lastMaintenanceDate: DateTime(2023, 12, 5),
        purchaseCost: 3100000.0,
        currentBookValue: 2400000.0,
        assignedDepartmentId: 'Media & Technical',
        notes: 'Main projection unit for center screen.',
      ),
      AssetModel(
        id: 'asset-power-01',
        name: 'Mikano 100KVA Soundproof Diesel Generator',
        category: 'Office Equipment',
        condition: 'Good',
        location: 'Power House Enclosure',
        tagId: 'PWR-GEN-001',
        serialNumber: 'MK-100KVA-2022',
        vendor: 'Mikano International Ltd',
        purchaseDate: DateTime(2022, 3, 1),
        lastMaintenanceDate: DateTime(2024, 2, 10),
        purchaseCost: 18500000.0,
        currentBookValue: 15200000.0,
        assignedDepartmentId: 'Maintenance & Operations',
        notes: 'Serviced every 250 operating hours.',
      ),
      AssetModel(
        id: 'asset-furn-01',
        name: 'Auditorium Ergonomic Padded Chairs (500 Units)',
        category: 'Furniture & Fixtures',
        condition: 'Good',
        location: 'Main Auditorium Ground Floor',
        tagId: 'AUD-FUR-001',
        serialNumber: 'FUR-SEAT-500',
        vendor: 'Vava Furniture Ltd',
        purchaseDate: DateTime(2022, 1, 15),
        lastMaintenanceDate: DateTime(2023, 10, 1),
        purchaseCost: 15000000.0,
        currentBookValue: 11500000.0,
        assignedDepartmentId: 'Ushering & Protocol',
        notes: 'Navy blue cushioned interlocking chairs.',
      ),
      AssetModel(
        id: 'asset-furn-02',
        name: 'Senior Pastor Executive Mahogany Desk & Ergonomic Chair',
        category: 'Furniture & Fixtures',
        condition: 'Excellent',
        location: 'Pastoral Suite - Office 1',
        tagId: 'ADM-FUR-001',
        serialNumber: 'EXEC-MAH-01',
        vendor: 'Homedox Interiors Ikeja',
        purchaseDate: DateTime(2023, 2, 28),
        lastMaintenanceDate: DateTime(2023, 8, 14),
        purchaseCost: 1200000.0,
        currentBookValue: 1050000.0,
        assignedDepartmentId: 'Administration',
        notes: 'Solid mahogany wood with leather swivel chair.',
      ),
      AssetModel(
        id: 'asset-media-03',
        name: 'Apple MacBook Pro 16" M2 Max (32GB RAM, 1TB SSD)',
        category: 'Electronics & Media',
        condition: 'Excellent',
        location: 'Media Editing Suite',
        tagId: 'ADM-MED-003',
        serialNumber: 'C02G99XXMD6R',
        vendor: 'iStore Ikeja City Mall',
        purchaseDate: DateTime(2023, 5, 20),
        lastMaintenanceDate: DateTime(2024, 1, 20),
        purchaseCost: 2900000.0,
        currentBookValue: 2500000.0,
        assignedDepartmentId: 'Media & Technical',
        notes: 'Used for live streaming & video editing.',
      ),
      AssetModel(
        id: 'asset-veh-01',
        name: 'Toyota Coaster Bus (30-Seater Air Conditioned)',
        category: 'Vehicles',
        condition: 'Fair',
        location: 'Church Parking Bay',
        tagId: 'VEH-BUS-001',
        serialNumber: 'JT153CB000918',
        vendor: 'Elizade Motors Lagos',
        purchaseDate: DateTime(2019, 7, 10),
        lastMaintenanceDate: DateTime(2024, 2, 15),
        purchaseCost: 28000000.0,
        currentBookValue: 16000000.0,
        assignedDepartmentId: 'Protocol & Transport',
        notes: 'Requires minor brake pad replacement.',
      ),
    ];

    for (final item in samples) {
      batch.set(colRef.doc(item.id), item.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }
}
