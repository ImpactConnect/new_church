import 'package:cloud_firestore/cloud_firestore.dart';

enum EmailFolder { inbox, sent, draft }

class AttachmentItem {
  final String name;
  final int size; // bytes
  final String? base64Content;
  final String? url;

  const AttachmentItem({
    required this.name,
    required this.size,
    this.base64Content,
    this.url,
  });

  factory AttachmentItem.fromMap(Map<String, dynamic> map) {
    return AttachmentItem(
      name: map['name'] ?? '',
      size: (map['size'] ?? 0) as int,
      base64Content: map['base64Content'],
      url: map['url'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'size': size,
        'base64Content': base64Content,
        'url': url,
      };
}

class FormalEmailModel {
  final String id;
  final String branchId;
  final EmailFolder folder; // inbox, sent, draft
  final String fromAddress;
  final String fromName;
  final List<String> toAddresses;
  final List<String> ccAddresses;
  final String subject;
  final String body;
  final List<AttachmentItem> attachments;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String createdBy;
  final String createdByName;
  final bool isRead;

  const FormalEmailModel({
    required this.id,
    required this.branchId,
    required this.folder,
    required this.fromAddress,
    required this.fromName,
    required this.toAddresses,
    this.ccAddresses = const [],
    required this.subject,
    required this.body,
    this.attachments = const [],
    required this.createdAt,
    this.sentAt,
    required this.createdBy,
    required this.createdByName,
    this.isRead = true,
  });

  factory FormalEmailModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FormalEmailModel(
      id: doc.id,
      branchId: d['branchId'] ?? '',
      folder: EmailFolder.values.firstWhere(
        (e) => e.name == (d['folder'] ?? 'sent'),
        orElse: () => EmailFolder.sent,
      ),
      fromAddress: d['fromAddress'] ?? '',
      fromName: d['fromName'] ?? '',
      toAddresses: List<String>.from(d['toAddresses'] ?? []),
      ccAddresses: List<String>.from(d['ccAddresses'] ?? []),
      subject: d['subject'] ?? '(No Subject)',
      body: d['body'] ?? '',
      attachments: (d['attachments'] as List? ?? [])
          .map((item) => AttachmentItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? '',
      isRead: d['isRead'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId,
        'folder': folder.name,
        'fromAddress': fromAddress,
        'fromName': fromName,
        'toAddresses': toAddresses,
        'ccAddresses': ccAddresses,
        'subject': subject,
        'body': body,
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'isRead': isRead,
      };

  FormalEmailModel copyWith({
    String? id,
    EmailFolder? folder,
    String? fromAddress,
    String? fromName,
    List<String>? toAddresses,
    List<String>? ccAddresses,
    String? subject,
    String? body,
    List<AttachmentItem>? attachments,
    DateTime? sentAt,
    bool? isRead,
  }) =>
      FormalEmailModel(
        id: id ?? this.id,
        branchId: branchId,
        folder: folder ?? this.folder,
        fromAddress: fromAddress ?? this.fromAddress,
        fromName: fromName ?? this.fromName,
        toAddresses: toAddresses ?? this.toAddresses,
        ccAddresses: ccAddresses ?? this.ccAddresses,
        subject: subject ?? this.subject,
        body: body ?? this.body,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
        sentAt: sentAt ?? this.sentAt,
        createdBy: createdBy,
        createdByName: createdByName,
        isRead: isRead ?? this.isRead,
      );
}
