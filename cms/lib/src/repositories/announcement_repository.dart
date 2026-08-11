import 'package:cms/src/features/announcements/models/announcement_model.dart';

abstract class AnnouncementRepository {
  Stream<List<AnnouncementModel>> watchAnnouncements(String branchId, {String? status});
  Future<void> createAnnouncement(String branchId, AnnouncementModel announcement);
  Future<void> approveAnnouncement(String branchId, String id, String approvedBy, String approvedByName);
  Future<void> rejectAnnouncement(String branchId, String id, String reason);
}
