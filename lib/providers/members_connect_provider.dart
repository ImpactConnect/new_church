import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/announcement.dart';
import '../models/testimony.dart';
import '../services/member_service.dart';
import '../services/announcement_service.dart';
import '../services/testimony_service.dart';

class MembersConnectProvider extends ChangeNotifier {
  final MemberService _memberService = MemberService();
  final AnnouncementService _announcementService = AnnouncementService();
  final TestimonyService _testimonyService = TestimonyService();

  List<Member> celebrants = [];
  List<Announcement> announcements = [];
  List<Testimony> testimonies = [];

  bool isLoadingCelebrants = false; // Default false — stream settles instantly
  bool isLoadingAnnouncements = true;
  bool isLoadingTestimonies = true;

  MembersConnectProvider() {
    _initStreams();
  }

  void _initStreams() {
    _memberService.getDailyCelebrantsStream().listen(
      (data) {
        celebrants = data;
        isLoadingCelebrants = false;
        notifyListeners();
      },
      onError: (_) {
        isLoadingCelebrants = false;
        notifyListeners();
      },
    );

    _announcementService.getAnnouncementsStream().listen((data) {
      announcements = data;
      isLoadingAnnouncements = false;
      notifyListeners();
    });

    _testimonyService.getTestimoniesStream().listen((data) {
      testimonies = data;
      isLoadingTestimonies = false;
      notifyListeners();
    });
  }

  List<Member> get todaysCelebrants => celebrants;
}
