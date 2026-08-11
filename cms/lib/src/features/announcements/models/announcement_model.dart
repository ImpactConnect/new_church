import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.targetAudience, // 'all', 'youth', 'choir', etc.
    required this.status, // 'draft', 'pending', 'approved', 'rejected'
    required this.requestedBy,
    required this.requestedByName,
    required this.createdAt,
    this.approvedBy,
    this.approvedByName,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final String content;
  final String targetAudience;
  final String status;
  final String requestedBy;
  final String requestedByName;
  final DateTime createdAt;
  final String? approvedBy;
  final String? approvedByName;
  final String? rejectionReason;

  factory AnnouncementModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AnnouncementModel(
      id: id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      targetAudience: data['targetAudience'] as String? ?? 'all',
      status: data['status'] as String? ?? 'draft',
      requestedBy: data['requestedBy'] as String? ?? '',
      requestedByName: data['requestedByName'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      approvedBy: data['approvedBy'] as String?,
      approvedByName: data['approvedByName'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'content': content,
    'targetAudience': targetAudience,
    'status': status,
    'requestedBy': requestedBy,
    'requestedByName': requestedByName,
    'createdAt': createdAt.toIso8601String(),
    if (approvedBy != null) 'approvedBy': approvedBy,
    if (approvedByName != null) 'approvedByName': approvedByName,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };

  AnnouncementModel copyWith({
    String? title,
    String? content,
    String? targetAudience,
    String? status,
    String? approvedBy,
    String? approvedByName,
    String? rejectionReason,
  }) => AnnouncementModel(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    targetAudience: targetAudience ?? this.targetAudience,
    status: status ?? this.status,
    requestedBy: requestedBy,
    requestedByName: requestedByName,
    createdAt: createdAt,
    approvedBy: approvedBy ?? this.approvedBy,
    approvedByName: approvedByName ?? this.approvedByName,
    rejectionReason: rejectionReason ?? this.rejectionReason,
  );

  @override
  List<Object?> get props => [id, title, status, createdAt];
}
