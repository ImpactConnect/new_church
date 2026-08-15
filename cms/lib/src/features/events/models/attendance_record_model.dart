import 'package:equatable/equatable.dart';

class AttendanceRecordModel extends Equatable {
  const AttendanceRecordModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventCategory,
    required this.date,
    required this.dayType, // 'weekday' | 'weekend'
    required this.male,
    required this.female,
    required this.adult,
    required this.youth,
    required this.children,
    required this.total,
    this.recordedBy,
    this.recordedByName,
    this.createdAt,
  });

  final String id;
  final String eventId;
  final String eventName;
  final String eventCategory;
  final DateTime date;
  final String dayType;
  final int male;
  final int female;
  final int adult;
  final int youth;
  final int children;
  final int total;
  final String? recordedBy;
  final String? recordedByName;
  final DateTime? createdAt;

  factory AttendanceRecordModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawDate = data['date'] ?? data['dateTime'] ?? data['createdAt'];
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

    final m = (data['male'] as num?)?.toInt() ?? 0;
    final f = (data['female'] as num?)?.toInt() ?? 0;
    final a = (data['adult'] as num?)?.toInt() ?? 0;
    final y = (data['youth'] as num?)?.toInt() ?? 0;
    final c = (data['children'] as num?)?.toInt() ?? 0;
    final tot = (data['total'] as num?)?.toInt() ?? (data['headcount'] as num?)?.toInt() ?? (m + f > 0 ? m + f : a + y + c);

    return AttendanceRecordModel(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      eventName: data['eventName'] as String? ?? data['title'] as String? ?? 'Church Service',
      eventCategory: data['eventCategory'] as String? ?? data['category'] as String? ?? 'Sunday Service',
      date: dt,
      dayType: data['dayType'] as String? ?? (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday ? 'weekend' : 'weekday'),
      male: m,
      female: f,
      adult: a,
      youth: y,
      children: c,
      total: tot,
      recordedBy: data['recordedBy'] as String?,
      recordedByName: data['recordedByName'] as String?,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'eventName': eventName,
    'eventCategory': eventCategory,
    'date': date.toIso8601String(),
    'dayType': dayType,
    'male': male,
    'female': female,
    'adult': adult,
    'children': children,
    'youth': youth,
    'total': total,
    if (recordedBy != null) 'recordedBy': recordedBy,
    if (recordedByName != null) 'recordedByName': recordedByName,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  @override
  List<Object?> get props => [id, eventId, eventName, date, total];
}
