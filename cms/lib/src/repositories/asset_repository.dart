import 'package:cms/src/features/assets/models/asset_model.dart';

abstract class AssetRepository {
  Stream<List<AssetModel>> watchAssets(String branchId);
  Future<void> saveAsset(String branchId, AssetModel asset);
  Future<void> deleteAsset(String branchId, String assetId);
}
