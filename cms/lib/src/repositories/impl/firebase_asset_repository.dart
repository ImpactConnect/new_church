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
  Stream<List<AssetModel>> watchAssets(String branchId) =>
      _col(branchId).orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => AssetModel.fromFirestore(d.data(), d.id)).toList(),
      );

  @override
  Future<void> saveAsset(String branchId, AssetModel asset) async {
    final id = asset.id.isEmpty ? _uuid.v4() : asset.id;
    await _col(branchId).doc(id).set(asset.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteAsset(String branchId, String assetId) async {
    await _col(branchId).doc(assetId).delete();
  }
}
