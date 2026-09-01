import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageChannel { sms, push, email, whatsapp }

enum MessageStatus { draft, sending, sent, failed, partial }

enum RecipientSegment { all, department, group, gender, branch }

class MessageModel {
  final String id;
  final String branchId;
  final MessageChannel channel;
  final String? subject;
  final String body;
  final RecipientSegment recipientSegment;
  final String? recipientFilter; // department id, group id, gender value, branch id
  final int recipientCount;
  final int sentCount;
  final int failedCount;
  final MessageStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String createdBy; // uid
  final String createdByName;
  final DateTime createdAt;
  final List<String>? failedRecipients;

  const MessageModel({
    required this.id,
    required this.branchId,
    required this.channel,
    this.subject,
    required this.body,
    required this.recipientSegment,
    this.recipientFilter,
    this.recipientCount = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.failedRecipients,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      branchId: d['branchId'] ?? '',
      channel: MessageChannel.values.firstWhere(
        (e) => e.name == (d['channel'] ?? 'sms'),
        orElse: () => MessageChannel.sms,
      ),
      subject: d['subject'],
      body: d['body'] ?? '',
      recipientSegment: RecipientSegment.values.firstWhere(
        (e) => e.name == (d['recipientSegment'] ?? 'all'),
        orElse: () => RecipientSegment.all,
      ),
      recipientFilter: d['recipientFilter'],
      recipientCount: (d['recipientCount'] ?? 0) as int,
      sentCount: (d['sentCount'] ?? 0) as int,
      failedCount: (d['failedCount'] ?? 0) as int,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'draft'),
        orElse: () => MessageStatus.draft,
      ),
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      failedRecipients: (d['failedRecipients'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId,
        'channel': channel.name,
        'subject': subject,
        'body': body,
        'recipientSegment': recipientSegment.name,
        'recipientFilter': recipientFilter,
        'recipientCount': recipientCount,
        'sentCount': sentCount,
        'failedCount': failedCount,
        'status': status.name,
        'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
        'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'failedRecipients': failedRecipients,
      };

  MessageModel copyWith({
    String? id,
    MessageChannel? channel,
    String? subject,
    String? body,
    RecipientSegment? recipientSegment,
    String? recipientFilter,
    int? recipientCount,
    int? sentCount,
    int? failedCount,
    MessageStatus? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    List<String>? failedRecipients,
  }) =>
      MessageModel(
        id: id ?? this.id,
        branchId: branchId,
        channel: channel ?? this.channel,
        subject: subject ?? this.subject,
        body: body ?? this.body,
        recipientSegment: recipientSegment ?? this.recipientSegment,
        recipientFilter: recipientFilter ?? this.recipientFilter,
        recipientCount: recipientCount ?? this.recipientCount,
        sentCount: sentCount ?? this.sentCount,
        failedCount: failedCount ?? this.failedCount,
        status: status ?? this.status,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        sentAt: sentAt ?? this.sentAt,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: createdAt,
        failedRecipients: failedRecipients ?? this.failedRecipients,
      );
}
