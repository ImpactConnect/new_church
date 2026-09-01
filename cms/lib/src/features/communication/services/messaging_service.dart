import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/communication/models/communication_settings_model.dart';

/// Result of a messaging send attempt.
class SendResult {
  final int sent;
  final int failed;
  final List<String> failedRecipients;
  final String? errorMessage;

  const SendResult({
    required this.sent,
    required this.failed,
    this.failedRecipients = const [],
    this.errorMessage,
  });
}

/// Resolved contact info for a member.
class MemberContact {
  final String memberId;
  final String? phone;
  final String? email;
  final String? fcmToken;

  const MemberContact({
    required this.memberId,
    this.phone,
    this.email,
    this.fcmToken,
  });
}

/// Handles outbound messaging across all channels.
class MessagingService {
  const MessagingService({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  // ─── Recipient resolution ────────────────────────────────────────────────────

  /// Fetches member contacts from Firestore filtered by the given segment.
  Future<List<MemberContact>> resolveRecipients({
    required String branchId,
    required String segment,
    String? filter,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('branches').doc(branchId).collection('members');

    switch (segment) {
      case 'department':
        if (filter != null && filter.isNotEmpty) {
          query = query.where('departmentId', isEqualTo: filter);
        }
        break;
      case 'gender':
        if (filter != null && filter.isNotEmpty) {
          query = query.where('gender', isEqualTo: filter);
        }
        break;
      case 'group':
        if (filter != null && filter.isNotEmpty) {
          query = query.where('subGroupId', isEqualTo: filter);
        }
        break;
      case 'branch':
        if (filter != null && filter.isNotEmpty && filter != branchId) {
          query = _db.collection('branches').doc(filter).collection('members');
        }
        break;
      case 'all':
      default:
        break; // no additional filter
    }

    final snap = await query.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return MemberContact(
        memberId: doc.id,
        phone: d['phone'] as String?,
        email: d['email'] as String?,
        fcmToken: d['fcmToken'] as String?,
      );
    }).toList();
  }

  // ─── SMS via Termii ───────────────────────────────────────────────────────────

  Future<SendResult> sendSms({
    required List<String> phones,
    required String message,
    required CommunicationSettingsModel settings,
  }) async {
    if (!settings.hasSmsConfig) {
      return const SendResult(
        sent: 0, failed: 0,
        errorMessage: 'SMS not configured. Please set Termii API key in Settings.',
      );
    }

    // Termii bulk SMS endpoint (send to multiple numbers at once)
    final validPhones = phones.where((p) => p.isNotEmpty).toList();
    if (validPhones.isEmpty) {
      return const SendResult(sent: 0, failed: 0, errorMessage: 'No valid phone numbers found.');
    }

    // Format numbers for Nigerian format (234XXXXXXXXXX)
    final formatted = validPhones.map(_formatNgPhone).where((p) => p != null).cast<String>().toList();

    int sent = 0;
    int failed = 0;
    final failedNums = <String>[];

    // Termii allows up to 100 numbers per batch — chunk if needed
    const batchSize = 100;
    for (int i = 0; i < formatted.length; i += batchSize) {
      final batch = formatted.sublist(i, (i + batchSize).clamp(0, formatted.length));
      try {
        final body = jsonEncode({
          'to': batch,
          'from': settings.termiiSenderId,
          'sms': message,
          'type': 'plain',
          'api_key': settings.termiiApiKey,
          'channel': 'generic',
        });

        final response = await http.post(
          Uri.parse('https://api.ng.termii.com/api/sms/send/bulk'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          sent += batch.length;
        } else {
          failed += batch.length;
          failedNums.addAll(batch);
        }
      } catch (e) {
        failed += batch.length;
        failedNums.addAll(batch);
      }
    }

    return SendResult(sent: sent, failed: failed, failedRecipients: failedNums);
  }

  // ─── WhatsApp via Termii WhatsApp channel ────────────────────────────────────

  Future<SendResult> sendWhatsApp({
    required List<String> phones,
    required String templateId,
    required String message,
    required CommunicationSettingsModel settings,
  }) async {
    if (!settings.hasWhatsAppConfig) {
      return const SendResult(
        sent: 0, failed: 0,
        errorMessage: 'WhatsApp not configured. Enable it in Settings with a valid Termii key and template ID.',
      );
    }

    final validPhones = phones.where((p) => p.isNotEmpty).toList();
    if (validPhones.isEmpty) {
      return const SendResult(sent: 0, failed: 0, errorMessage: 'No valid phone numbers found.');
    }

    final formatted = validPhones.map(_formatNgPhone).where((p) => p != null).cast<String>().toList();

    int sent = 0;
    int failed = 0;
    final failedNums = <String>[];

    // Termii WhatsApp sends one message per number
    for (final phone in formatted) {
      try {
        final body = jsonEncode({
          'api_key': settings.termiiApiKey,
          'to': phone,
          'from': settings.termiiSenderId,
          'sms': message,
          'type': 'plain',
          'channel': 'whatsapp',
          'media': null,
        });

        final response = await http.post(
          Uri.parse('https://api.ng.termii.com/api/sms/send'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          sent++;
        } else {
          failed++;
          failedNums.add(phone);
        }
      } catch (_) {
        failed++;
        failedNums.add(phone);
      }
    }

    return SendResult(sent: sent, failed: failed, failedRecipients: failedNums);
  }

  // ─── Push Notifications via FCM HTTP v1 ─────────────────────────────────────

  Future<SendResult> sendPush({
    required List<String> fcmTokens,
    required String title,
    required String body,
    required CommunicationSettingsModel settings,
    Map<String, String>? data,
  }) async {
    if (!settings.hasPushConfig) {
      return const SendResult(
        sent: 0, failed: 0,
        errorMessage: 'Push notifications not configured. Please set FCM Server Key in Settings.',
      );
    }

    final validTokens = fcmTokens.where((t) => t.isNotEmpty).toList();
    if (validTokens.isEmpty) {
      return const SendResult(sent: 0, failed: 0, errorMessage: 'No FCM tokens found for selected recipients.');
    }

    int sent = 0;
    int failed = 0;
    final failedTokens = <String>[];

    // FCM legacy HTTP API — supports multicast up to 500 tokens per request
    const batchSize = 500;
    for (int i = 0; i < validTokens.length; i += batchSize) {
      final batch = validTokens.sublist(i, (i + batchSize).clamp(0, validTokens.length));
      try {
        final payload = jsonEncode({
          'registration_ids': batch,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        });

        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=${settings.fcmServerKey}',
          },
          body: payload,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          sent += (decoded['success'] ?? 0) as int;
          failed += (decoded['failure'] ?? 0) as int;
        } else {
          failed += batch.length;
          failedTokens.addAll(batch);
        }
      } catch (_) {
        failed += batch.length;
        failedTokens.addAll(batch);
      }
    }

    return SendResult(sent: sent, failed: failed, failedRecipients: failedTokens);
  }

  // ─── Email via Resend API ─────────────────────────────────────────────────────

  Future<SendResult> sendEmail({
    required List<String> addresses,
    required String subject,
    required String htmlBody,
    required CommunicationSettingsModel settings,
  }) async {
    if (!settings.hasEmailConfig) {
      return const SendResult(
        sent: 0, failed: 0,
        errorMessage: 'Email not configured. Please set Resend API key and From address in Settings.',
      );
    }

    final validAddresses = addresses.where((e) => e.isNotEmpty && e.contains('@')).toList();
    if (validAddresses.isEmpty) {
      return const SendResult(sent: 0, failed: 0, errorMessage: 'No valid email addresses found.');
    }

    int sent = 0;
    int failed = 0;
    final failedEmails = <String>[];

    // Resend supports batch sending up to 100 per request
    const batchSize = 100;
    for (int i = 0; i < validAddresses.length; i += batchSize) {
      final batch = validAddresses.sublist(i, (i + batchSize).clamp(0, validAddresses.length));
      try {
        final fromDisplay = settings.resendFromName.isNotEmpty
            ? '${settings.resendFromName} <${settings.resendFromEmail}>'
            : settings.resendFromEmail;

        final payload = jsonEncode({
          'from': fromDisplay,
          'to': batch,
          'subject': subject,
          'html': htmlBody,
        });

        final response = await http.post(
          Uri.parse('https://api.resend.com/emails'),
          headers: {
            'Authorization': 'Bearer ${settings.resendApiKey}',
            'Content-Type': 'application/json',
          },
          body: payload,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          sent += batch.length;
        } else {
          failed += batch.length;
          failedEmails.addAll(batch);
        }
      } catch (_) {
        failed += batch.length;
        failedEmails.addAll(batch);
      }
    }

    return SendResult(sent: sent, failed: failed, failedRecipients: failedEmails);
  }

  // ─── Formal Email (To, CC, Attachments) via Resend API ────────────────────────

  Future<SendResult> sendFormalEmail({
    required List<String> to,
    List<String> cc = const [],
    required String subject,
    required String htmlBody,
    List<Map<String, dynamic>> attachments = const [],
    required CommunicationSettingsModel settings,
  }) async {
    if (!settings.hasEmailConfig) {
      return const SendResult(
        sent: 0,
        failed: 0,
        errorMessage: 'Email not configured. Please set Resend API key and From address in Settings.',
      );
    }

    final validTo = to.where((e) => e.isNotEmpty && e.contains('@')).toList();
    if (validTo.isEmpty) {
      return const SendResult(sent: 0, failed: 0, errorMessage: 'No valid recipient email addresses specified.');
    }

    final validCc = cc.where((e) => e.isNotEmpty && e.contains('@')).toList();

    try {
      final fromDisplay = settings.resendFromName.isNotEmpty
          ? '${settings.resendFromName} <${settings.resendFromEmail}>'
          : settings.resendFromEmail;

      final Map<String, dynamic> payload = {
        'from': fromDisplay,
        'to': validTo,
        'subject': subject,
        'html': htmlBody,
      };

      if (validCc.isNotEmpty) {
        payload['cc'] = validCc;
      }

      if (attachments.isNotEmpty) {
        payload['attachments'] = attachments;
      }

      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer ${settings.resendApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SendResult(sent: validTo.length + validCc.length, failed: 0);
      } else {
        final err = response.body;
        return SendResult(sent: 0, failed: validTo.length, errorMessage: 'Resend API error (${response.statusCode}): $err');
      }
    } catch (e) {
      return SendResult(sent: 0, failed: validTo.length, errorMessage: 'Failed to send formal email: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Converts Nigerian phone numbers to E.164 format (234XXXXXXXXXX)
  String? _formatNgPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.startsWith('+234')) return cleaned.substring(1);
    if (cleaned.startsWith('234') && cleaned.length >= 13) return cleaned;
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '234${cleaned.substring(1)}';
    }
    // Assume it's already a 10-digit number without country code
    if (cleaned.length == 10) return '234$cleaned';
    return cleaned;
  }
}
