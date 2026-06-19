import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('timePosted', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList(),
        );
  }
}
