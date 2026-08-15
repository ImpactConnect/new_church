import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/announcements/models/announcement_model.dart';
import 'package:cms/src/repositories/announcement_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseAnnouncementRepository implements AnnouncementRepository {
  FirebaseAnnouncementRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('announcements');

  @override
  Stream<List<AnnouncementModel>> watchAnnouncements(String branchId, {String? status}) {
    Query<Map<String, dynamic>> query = _col(branchId);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
      (s) => s.docs.map((d) => AnnouncementModel.fromFirestore(d.data(), d.id)).toList(),
    );
  }

  @override
  Future<void> createAnnouncement(String branchId, AnnouncementModel announcement) async {
    final id = announcement.id.isEmpty ? _uuid.v4() : announcement.id;
    await _col(branchId).doc(id).set(announcement.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> approveAnnouncement(
    String branchId,
    String id,
    String approvedBy,
    String approvedByName,
  ) async {
    await _col(branchId).doc(id).update({
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
    });
  }

  @override
  Future<void> rejectAnnouncement(String branchId, String id, String reason) async {
    await _col(branchId).doc(id).update({
      'status': 'rejected',
      'rejectionReason': reason,
    });
  }
}
