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
    this.status = 'approved', // 'pending_approval', 'approved', 'rejected'
    this.eventType = 'special_event', // 'yearly_calendar', 'wedding_programme', 'revival_programme', 'conference', 'anniversary', 'special_event'
    this.year = 2026,
    this.startDate,
    this.endDate,
    this.createdByRole,
    this.createdByName,
    this.rejectionReason,
    this.mediaUrls = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String category;
  final int headcount;
  final String? departmentId;
  final String status;
  final String eventType;
  final int year;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? createdByRole;
  final String? createdByName;
  final String? rejectionReason;
  final List<String> mediaUrls;

  DateTime get effectiveStartDate => startDate ?? dateTime;
  DateTime get effectiveEndDate => endDate ?? dateTime;

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending_approval' || status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory EventModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawDate = data['dateTime'] ?? data['date'] ?? data['startDate'] ?? data['createdAt'];
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

    DateTime? sDate;
    if (data['startDate'] != null) {
      if (data['startDate'] is DateTime) {
        sDate = data['startDate'];
      } else if (data['startDate'].runtimeType.toString().contains('Timestamp')) {
        sDate = (data['startDate'] as dynamic).toDate();
      } else {
        sDate = DateTime.tryParse(data['startDate'].toString());
      }
    }

    DateTime? eDate;
    if (data['endDate'] != null) {
      if (data['endDate'] is DateTime) {
        eDate = data['endDate'];
      } else if (data['endDate'].runtimeType.toString().contains('Timestamp')) {
        eDate = (data['endDate'] as dynamic).toDate();
      } else {
        eDate = DateTime.tryParse(data['endDate'].toString());
      }
    }

    return EventModel(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? data['body'] as String? ?? '',
      dateTime: dt,
      location: data['location'] as String? ?? data['venue'] as String? ?? 'Main Auditorium',
      category: data['category'] as String? ?? (data['type'] == 'recurring' ? 'Sunday Service' : 'Special Event'),
      headcount: (data['headcount'] as num?)?.toInt() ?? (data['totalCount'] as num?)?.toInt() ?? 0,
      departmentId: data['departmentId'] as String?,
      status: data['status'] as String? ?? 'approved',
      eventType: data['eventType'] as String? ?? 'special_event',
      year: (data['year'] as num?)?.toInt() ?? dt.year,
      startDate: sDate,
      endDate: eDate,
      createdByRole: data['createdByRole'] as String?,
      createdByName: data['createdByName'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      mediaUrls: (data['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (data['imageUrl'] != null ? [data['imageUrl'].toString()] : const []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'location': location,
    'venue': location,
    'category': category,
    'headcount': headcount,
    if (departmentId != null) 'departmentId': departmentId,
    'status': status,
    'eventType': eventType,
    'year': year,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (createdByRole != null) 'createdByRole': createdByRole,
    if (createdByName != null) 'createdByName': createdByName,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    'mediaUrls': mediaUrls,
  };

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? category,
    int? headcount,
    String? departmentId,
    String? status,
    String? eventType,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    String? createdByRole,
    String? createdByName,
    String? rejectionReason,
    List<String>? mediaUrls,
  }) => EventModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    dateTime: dateTime ?? this.dateTime,
    location: location ?? this.location,
    category: category ?? this.category,
    headcount: headcount ?? this.headcount,
    departmentId: departmentId ?? this.departmentId,
    status: status ?? this.status,
    eventType: eventType ?? this.eventType,
    year: year ?? this.year,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdByRole: createdByRole ?? this.createdByRole,
    createdByName: createdByName ?? this.createdByName,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    mediaUrls: mediaUrls ?? this.mediaUrls,
  );

  @override
  List<Object?> get props => [id, title, dateTime, category, status, eventType];
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
