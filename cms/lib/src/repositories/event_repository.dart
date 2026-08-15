import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/events/models/attendance_record_model.dart';

abstract class EventRepository {
  Stream<List<EventModel>> watchEvents(String branchId);
  Future<void> saveEvent(String branchId, EventModel event);
  Future<void> deleteEvent(String branchId, String eventId);

  // Member Attendance
  Stream<List<AttendanceModel>> watchAttendance(String branchId, String eventId);
  Future<void> recordAttendance(String branchId, String eventId, List<AttendanceModel> records);
  Future<void> updateHeadcount(String branchId, String eventId, int headcount);

  // Demographic & Service Attendance Records
  Stream<List<AttendanceRecordModel>> watchDetailedAttendanceRecords(String branchId);
  Future<void> recordDetailedAttendance(String branchId, AttendanceRecordModel record);
}
