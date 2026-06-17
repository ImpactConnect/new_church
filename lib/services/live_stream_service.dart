import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'live_streams';

  /// Returns a real-time stream of the currently active live stream.
  /// Admin sets [isLive: true] on the Firestore document to activate it.
  Stream<LiveStream?> watchCurrentLiveStream() {
    return _firestore
        .collection(_collection)
        .where('isLive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final stream = LiveStream.fromFirestore(snapshot.docs.first);
      // If endTime is set and has passed, treat as ended
      if (stream.hasEnded) return null;
      return stream;
    });
  }

  /// One-shot fetch of the current live stream (for non-reactive use).
  Future<LiveStream?> getCurrentLiveStream() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isLive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final stream = LiveStream.fromFirestore(snapshot.docs.first);
      if (stream.hasEnded) return null;
      return stream;
    } on FirebaseException catch (e) {
      // Index not yet built — fallback without orderBy
      if (e.code == 'failed-precondition') {
        try {
          final snapshot = await _firestore
              .collection(_collection)
              .where('isLive', isEqualTo: true)
              .limit(1)
              .get();
          if (snapshot.docs.isEmpty) return null;
          final stream = LiveStream.fromFirestore(snapshot.docs.first);
          if (stream.hasEnded) return null;
          return stream;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns up to 5 upcoming scheduled streams.
  Future<List<LiveStream>> getUpcomingStreams() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .where('isLive', isEqualTo: false)
          .orderBy('startTime')
          .limit(5)
          .get();

      return snapshot.docs.map(LiveStream.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns up to 10 past streams (ended).
  Future<List<LiveStream>> getPastStreams() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .orderBy('endTime', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map(LiveStream.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }
}
