import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/correspondence/models/correspondence_model.dart';
import 'package:cms/src/repositories/correspondence_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseCorrespondenceRepository implements CorrespondenceRepository {
  FirebaseCorrespondenceRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('correspondence');

  @override
  Stream<List<CorrespondenceModel>> watchCorrespondence(String branchId, {String? type}) {
    Query<Map<String, dynamic>> query = _col(branchId).orderBy('date', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map(
      (s) => s.docs.map((d) => CorrespondenceModel.fromFirestore(d.data(), d.id)).toList(),
    );
  }

  @override
  Future<void> logCorrespondence(String branchId, CorrespondenceModel item) async {
    final id = item.id.isEmpty ? _uuid.v4() : item.id;
    await _col(branchId).doc(id).set(item.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteCorrespondence(String branchId, String id) async {
    await _col(branchId).doc(id).delete();
  }
}
