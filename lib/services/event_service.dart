import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../utils/toast_utils.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Get all events for Mobile Event Page ──────────────────────────────────
  // Only published events (edited & published by admin with isPublishedToApp == true
  // or standalone admin events) appear on the member Events Screen.
  Future<Map<String, List<Event>>> getAllEvents() async {
    try {
      final Map<String, DocumentSnapshot> combinedDocs = {};

      try {
        final rootSnap = await _firestore.collection('events').get();
        for (final doc in rootSnap.docs) {
          combinedDocs[doc.id] = doc;
        }
      } catch (e) {
        print('Error fetching root events: $e');
      }

      final now = DateTime.now();

      final List<Event> upcomingEvents = [];
      final List<Event> pastEvents = [];

      for (final doc in combinedDocs.values) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final event = Event.fromFirestore(doc);

          // 1. Must be approved
          if (!event.isApproved) continue;

          // 2. Only events explicitly edited & published by admin appear on the Event page.
          // Raw un-edited yearly calendar items stay on ChurchCalendarScreen only.
          final bool isPublishedToApp = data['isPublishedToApp'] == true;
          final bool hasFlyer = data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
          final bool isStandalone = data['eventType'] != 'yearly_calendar' && data['eventType'] != null;

          final bool isPublishedForApp = isPublishedToApp || hasFlyer || isStandalone;
          if (!isPublishedForApp) continue;

          final isCurrentMonth = event.startDate.year == now.year && event.startDate.month == now.month;
          final isFutureOrCurrent = event.isUpcoming || isCurrentMonth;

          if (isFutureOrCurrent) {
            upcomingEvents.add(event);
          } else {
            pastEvents.add(event);
          }
        } catch (e) {
          print('Error parsing event doc ${doc.id}: $e');
        }
      }

      // Sort upcoming events ascending by start date
      upcomingEvents.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
      // Sort past events descending by end date
      pastEvents.sort((a, b) => b.endDate.compareTo(a.endDate));

      return {
        'upcoming': upcomingEvents,
        'past': pastEvents,
      };
    } catch (e) {
      print('Error getting events: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        ToastUtils.showToast('Permission denied reading events.');
      }
      return {'upcoming': [], 'past': []};
    }
  }

  // ─── Upcoming events stream ────────────────────────────────────────────────
  Stream<List<Event>> getUpcomingEventsStream({int limit = 3}) {
    return _firestore.collection('events').snapshots().map((snapshot) {
      final now = DateTime.now();
      final events = <Event>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final e = Event.fromFirestore(doc);

          final bool isPublishedToApp = data['isPublishedToApp'] == true;
          final bool hasFlyer = data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
          final bool isStandalone = data['eventType'] != 'yearly_calendar' && data['eventType'] != null;
          final bool isPublishedForApp = isPublishedToApp || hasFlyer || isStandalone;

          if (!isPublishedForApp) continue;

          final isCurrentMonth = e.startDate.year == now.year && e.startDate.month == now.month;
          if (e.isApproved && (e.isUpcoming || isCurrentMonth)) {
            events.add(e);
          }
        } catch (_) {}
      }
      events.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
      return events.take(limit).toList();
    });
  }

  // ─── Search events (client-side) ──────────────────────────────────────────
  Future<Map<String, List<Event>>> searchEvents(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final rootSnap = await _firestore.collection('events').get();

      final now = DateTime.now();

      final List<Event> upcomingEvents = [];
      final List<Event> pastEvents = [];

      for (final doc in rootSnap.docs) {
        try {
          final data = doc.data();
          final event = Event.fromFirestore(doc);
          if (!event.isApproved) continue;

          final bool isPublishedToApp = data['isPublishedToApp'] == true;
          final bool hasFlyer = data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
          final bool isStandalone = data['eventType'] != 'yearly_calendar' && data['eventType'] != null;
          final bool isPublishedForApp = isPublishedToApp || hasFlyer || isStandalone;
          if (!isPublishedForApp) continue;

          final matches =
              event.title.toLowerCase().contains(lowerQuery) ||
              event.description.toLowerCase().contains(lowerQuery) ||
              event.venue.toLowerCase().contains(lowerQuery);

          if (!matches) continue;

          final isCurrentMonth = event.startDate.year == now.year && event.startDate.month == now.month;
          final isFutureOrCurrent = event.isUpcoming || isCurrentMonth;

          if (isFutureOrCurrent) {
            upcomingEvents.add(event);
          } else {
            pastEvents.add(event);
          }
        } catch (_) {}
      }

      upcomingEvents.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
      pastEvents.sort((a, b) => b.endDate.compareTo(a.endDate));

      return {'upcoming': upcomingEvents, 'past': pastEvents};
    } catch (e) {
      print('Error searching events: $e');
      return {'upcoming': [], 'past': []};
    }
  }

  // ─── Get event by ID ───────────────────────────────────────────────────────
  Future<Event?> getEventById(String eventId) async {
    try {
      final docSnapshot =
          await _firestore.collection('events').doc(eventId).get();
      if (docSnapshot.exists) return Event.fromFirestore(docSnapshot);
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // ─── Add sample events for testing ────────────────────────────────────────
  Future<void> addSampleEvents() async {
    try {
      final batch = _firestore.batch();

      batch.set(_firestore.collection('events').doc(), {
        'title': 'Sunday Service',
        'description': 'Join us for our weekly Sunday service filled with worship and fellowship.',
        'imageUrl': '',
        'startDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2, hours: 2))),
        'venue': 'Main Sanctuary',
        'programmeTime': '10:00 AM - 12:00 PM',
        'status': 'approved',
        'isPublishedToApp': true,
        'eventType': 'sunday_service',
        'year': DateTime.now().year,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      ToastUtils.showToast('Sample event added successfully');
    } catch (e) {
      print('Unexpected error adding sample events: $e');
    }
  }
}
