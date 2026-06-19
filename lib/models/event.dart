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
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      venue: data['venue'] ?? '',
      programmeTime: data['programmeTime'] ?? '',
      joinLink: data['joinLink'] ?? '',
      recurrence: data['recurrence'] ?? 'none',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
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
  final DateTime? createdAt;
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
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
