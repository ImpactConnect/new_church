import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.programmeTime,
    this.joinLink = '',
    this.recurrence = 'none',
    required this.createdAt,
    this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final sDate = parseDate(data['startDate'] ?? data['dateTime'] ?? data['date']);
    final eDate = parseDate(data['endDate'] ?? data['dateTime'] ?? data['date']);

    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? (data['mediaUrls'] is List && (data['mediaUrls'] as List).isNotEmpty ? data['mediaUrls'].first.toString() : ''),
      startDate: sDate,
      endDate: eDate,
      venue: data['venue'] ?? data['location'] ?? 'Main Sanctuary',
      programmeTime: data['programmeTime'] ?? '',
      joinLink: data['joinLink'] ?? '',
      recurrence: data['recurrence'] ?? 'none',
      createdAt: data['createdAt'] != null
          ? parseDate(data['createdAt'])
          : sDate,
      updatedAt: data['updatedAt'] != null
          ? parseDate(data['updatedAt'])
          : null,
    );
  }
  
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String programmeTime;
  final String joinLink;
  final String recurrence;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isUpcoming => endDate.isAfter(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'venue': venue,
      'programmeTime': programmeTime,
      'joinLink': joinLink,
      'recurrence': recurrence,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
