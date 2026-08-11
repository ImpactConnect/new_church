import 'package:cms/src/features/correspondence/models/correspondence_model.dart';

abstract class CorrespondenceRepository {
  Stream<List<CorrespondenceModel>> watchCorrespondence(String branchId, {String? type});
  Future<void> logCorrespondence(String branchId, CorrespondenceModel item);
  Future<void> deleteCorrespondence(String branchId, String id);
}
