import 'package:equatable/equatable.dart';

class CorrespondenceModel extends Equatable {
  const CorrespondenceModel({
    required this.id,
    required this.type, // 'incoming' | 'outgoing'
    required this.subject,
    required this.senderOrRecipient,
    required this.date,
    required this.loggedBy,
    required this.loggedByName,
    this.notes,
    this.fileUrl,
    this.referenceNumber,
  });

  final String id;
  final String type;
  final String subject;
  final String senderOrRecipient;
  final DateTime date;
  final String loggedBy;
  final String loggedByName;
  final String? notes;
  final String? fileUrl;
  final String? referenceNumber;

  factory CorrespondenceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CorrespondenceModel(
      id: id,
      type: data['type'] as String? ?? 'incoming',
      subject: data['subject'] as String? ?? '',
      senderOrRecipient: data['senderOrRecipient'] as String? ?? '',
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      loggedBy: data['loggedBy'] as String? ?? '',
      loggedByName: data['loggedByName'] as String? ?? '',
      notes: data['notes'] as String?,
      fileUrl: data['fileUrl'] as String?,
      referenceNumber: data['referenceNumber'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type,
    'subject': subject,
    'senderOrRecipient': senderOrRecipient,
    'date': date.toIso8601String(),
    'loggedBy': loggedBy,
    'loggedByName': loggedByName,
    if (notes != null) 'notes': notes,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (referenceNumber != null) 'referenceNumber': referenceNumber,
  };

  @override
  List<Object?> get props => [id, type, subject, date];
}
