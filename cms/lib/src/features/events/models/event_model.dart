import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.category, // 'Sunday Service', 'Midweek', 'Vigil', 'Special Event'
    this.headcount = 0,
    this.departmentId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String category;
  final int headcount;
  final String? departmentId;

  factory EventModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawDate = data['dateTime'] ?? data['date'] ?? data['createdAt'];
    DateTime dt = DateTime.now();
    if (rawDate != null) {
      if (rawDate is DateTime) {
        dt = rawDate;
      } else if (rawDate.runtimeType.toString().contains('Timestamp')) {
        dt = (rawDate as dynamic).toDate();
      } else {
        dt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }
    return EventModel(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? data['body'] as String? ?? '',
      dateTime: dt,
      location: data['location'] as String? ?? 'Main Auditorium',
      category: data['category'] as String? ?? (data['type'] == 'recurring' ? 'Sunday Service' : 'Special Event'),
      headcount: (data['headcount'] as num?)?.toInt() ?? (data['totalCount'] as num?)?.toInt() ?? 0,
      departmentId: data['departmentId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'location': location,
    'category': category,
    'headcount': headcount,
    if (departmentId != null) 'departmentId': departmentId,
  };

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? category,
    int? headcount,
    String? departmentId,
  }) => EventModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    dateTime: dateTime ?? this.dateTime,
    location: location ?? this.location,
    category: category ?? this.category,
    headcount: headcount ?? this.headcount,
    departmentId: departmentId ?? this.departmentId,
  );

  @override
  List<Object?> get props => [id, title, dateTime, category];
}

class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.memberName,
    required this.status, // 'present', 'absent', 'excused'
    required this.timestamp,
  });

  final String id;
  final String eventId;
  final String memberId;
  final String memberName;
  final String status;
  final DateTime timestamp;

  factory AttendanceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      memberName: data['memberName'] as String? ?? '',
      status: data['status'] as String? ?? 'present',
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'memberId': memberId,
    'memberName': memberName,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, eventId, memberId, status];
}
