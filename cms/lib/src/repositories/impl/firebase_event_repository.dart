import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/repositories/event_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseEventRepository implements EventRepository {
  FirebaseEventRepository({required FirebaseFirestore firestore})
    : _db = firestore;
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _eventsCol(String branchId) =>
      _db.collection('branches').doc(branchId).collection('events');

  @override
  Stream<List<EventModel>> watchEvents(String branchId) =>
      _eventsCol(branchId).orderBy('dateTime', descending: true).snapshots().map(
        (s) => s.docs.map((d) => EventModel.fromFirestore(d.data(), d.id)).toList(),
      );

  @override
  Future<void> saveEvent(String branchId, EventModel event) async {
    final id = event.id.isEmpty ? _uuid.v4() : event.id;
    await _eventsCol(branchId).doc(id).set(event.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteEvent(String branchId, String eventId) async {
    await _eventsCol(branchId).doc(eventId).delete();
  }

  @override
  Stream<List<AttendanceModel>> watchAttendance(String branchId, String eventId) =>
      _eventsCol(branchId).doc(eventId).collection('attendance').snapshots().map(
        (s) => s.docs.map((d) => AttendanceModel.fromFirestore(d.data(), d.id)).toList(),
      );

  @override
  Future<void> recordAttendance(
    String branchId,
    String eventId,
    List<AttendanceModel> records,
  ) async {
    final batch = _db.batch();
    final attCol = _eventsCol(branchId).doc(eventId).collection('attendance');

    for (final rec in records) {
      final docRef = attCol.doc(rec.memberId);
      batch.set(docRef, rec.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();

    // Update event headcount
    final presentCount = records.where((r) => r.status == 'present').length;
    await updateHeadcount(branchId, eventId, presentCount);
  }

  @override
  Future<void> updateHeadcount(String branchId, String eventId, int headcount) async {
    await _eventsCol(branchId).doc(eventId).update({'headcount': headcount});
  }
}
