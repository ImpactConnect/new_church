import 'package:cloud_firestore/cloud_firestore.dart';

class CommunicationSettingsModel {
  // Termii (SMS + WhatsApp)
  final String termiiApiKey;
  final String termiiSenderId;

  // Resend (Email)
  final String resendApiKey;
  final String resendFromEmail;
  final String resendFromName;

  // Firebase Cloud Messaging (Push Notifications)
  final String fcmServerKey;

  // WhatsApp
  final bool whatsappEnabled;
  final String whatsappTemplateId;

  const CommunicationSettingsModel({
    this.termiiApiKey = '',
    this.termiiSenderId = '',
    this.resendApiKey = '',
    this.resendFromEmail = '',
    this.resendFromName = '',
    this.fcmServerKey = '',
    this.whatsappEnabled = false,
    this.whatsappTemplateId = '',
  });

  bool get hasSmsConfig => termiiApiKey.isNotEmpty && termiiSenderId.isNotEmpty;
  bool get hasEmailConfig => resendApiKey.isNotEmpty && resendFromEmail.isNotEmpty;
  bool get hasPushConfig => fcmServerKey.isNotEmpty;
  bool get hasWhatsAppConfig => whatsappEnabled && hasSmsConfig && whatsappTemplateId.isNotEmpty;

  factory CommunicationSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CommunicationSettingsModel(
      termiiApiKey: d['termiiApiKey'] ?? '',
      termiiSenderId: d['termiiSenderId'] ?? '',
      resendApiKey: d['resendApiKey'] ?? '',
      resendFromEmail: d['resendFromEmail'] ?? '',
      resendFromName: d['resendFromName'] ?? '',
      fcmServerKey: d['fcmServerKey'] ?? '',
      whatsappEnabled: d['whatsappEnabled'] ?? false,
      whatsappTemplateId: d['whatsappTemplateId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'termiiApiKey': termiiApiKey,
        'termiiSenderId': termiiSenderId,
        'resendApiKey': resendApiKey,
        'resendFromEmail': resendFromEmail,
        'resendFromName': resendFromName,
        'fcmServerKey': fcmServerKey,
        'whatsappEnabled': whatsappEnabled,
        'whatsappTemplateId': whatsappTemplateId,
      };

  CommunicationSettingsModel copyWith({
    String? termiiApiKey,
    String? termiiSenderId,
    String? resendApiKey,
    String? resendFromEmail,
    String? resendFromName,
    String? fcmServerKey,
    bool? whatsappEnabled,
    String? whatsappTemplateId,
  }) =>
      CommunicationSettingsModel(
        termiiApiKey: termiiApiKey ?? this.termiiApiKey,
        termiiSenderId: termiiSenderId ?? this.termiiSenderId,
        resendApiKey: resendApiKey ?? this.resendApiKey,
        resendFromEmail: resendFromEmail ?? this.resendFromEmail,
        resendFromName: resendFromName ?? this.resendFromName,
        fcmServerKey: fcmServerKey ?? this.fcmServerKey,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        whatsappTemplateId: whatsappTemplateId ?? this.whatsappTemplateId,
      );
}
