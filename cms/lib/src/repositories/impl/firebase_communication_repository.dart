import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/features/communication/models/message_model.dart';
import 'package:cms/src/features/communication/models/communication_settings_model.dart';
import 'package:cms/src/features/communication/models/formal_email_model.dart';
import 'package:cms/src/repositories/communication_repository.dart';

class FirebaseCommunicationRepository implements CommunicationRepository {
  FirebaseCommunicationRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String branchId) =>
      _db.collection('branches').doc(branchId).collection('communications');

  CollectionReference<Map<String, dynamic>> _emailCol(String branchId) =>
      _db.collection('branches').doc(branchId).collection('formal_emails');

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db.collection('config').doc('communicationSettings');

  @override
  Stream<List<MessageModel>> watchMessages(String branchId) {
    return _col(branchId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  @override
  Future<void> saveMessage(String branchId, MessageModel message) async {
    if (message.id.isEmpty) {
      final ref = _col(branchId).doc();
      await ref.set(message.copyWith(id: ref.id).toFirestore());
    } else {
      await _col(branchId).doc(message.id).set(message.toFirestore());
    }
  }

  @override
  Future<void> updateMessage(String branchId, MessageModel message) async {
    await _col(branchId).doc(message.id).update(message.toFirestore());
  }

  @override
  Future<CommunicationSettingsModel> getCommunicationSettings() async {
    final snap = await _settingsDoc.get();
    if (!snap.exists) return const CommunicationSettingsModel();
    return CommunicationSettingsModel.fromFirestore(snap);
  }

  @override
  Future<void> saveCommunicationSettings(CommunicationSettingsModel settings) async {
    await _settingsDoc.set(settings.toFirestore(), SetOptions(merge: true));
  }

  // ─── Formal Emails ──────────────────────────────────────────────────────────

  @override
  Stream<List<FormalEmailModel>> watchFormalEmails(String branchId, EmailFolder folder) {
    _seedFormalEmailsIfEmpty(branchId);
    return _emailCol(branchId)
        .where('folder', isEqualTo: folder.name)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(FormalEmailModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Future<void> saveFormalEmail(String branchId, FormalEmailModel email) async {
    if (email.id.isEmpty) {
      final ref = _emailCol(branchId).doc();
      await ref.set(email.copyWith(id: ref.id).toFirestore());
    } else {
      await _emailCol(branchId).doc(email.id).set(email.toFirestore());
    }
  }

  @override
  Future<void> deleteFormalEmail(String branchId, String emailId) async {
    await _emailCol(branchId).doc(emailId).delete();
  }

  Future<void> _seedFormalEmailsIfEmpty(String branchId) async {
    try {
      final snap = await _emailCol(branchId).limit(1).get();
      if (snap.docs.isEmpty) {
        final now = DateTime.now();
        final samples = [
          // Inbox Sample 1
          FormalEmailModel(
            id: 'sample-inbox-1',
            branchId: branchId,
            folder: EmailFolder.inbox,
            fromAddress: 'info@firstbanknigeria.com',
            fromName: 'First Bank Corporate Desk',
            toAddresses: ['pastor@churchname.org', 'secretary@churchname.org'],
            ccAddresses: ['finance@churchname.org'],
            subject: 'Monthly Church Account Statement & Corporate Banking Update',
            body: 'Dear Lead Pastor & Secretariat,\n\nPlease find attached the official monthly bank account statement for your church operating account #1012398472 for the period ending last month.\n\nShould you require any customized letter of reference or facility review, please reply to this email thread.\n\nWarm regards,\nFirst Bank Corporate Relationship Manager',
            attachments: const [
              AttachmentItem(name: 'Bank_Statement_Aug2026.pdf', size: 245000),
            ],
            createdAt: now.subtract(const Duration(days: 1)),
            createdBy: 'system',
            createdByName: 'First Bank Desk',
            isRead: false,
          ),
          // Inbox Sample 2
          FormalEmailModel(
            id: 'sample-inbox-2',
            branchId: branchId,
            folder: EmailFolder.inbox,
            fromAddress: 'projects@buildrightconsult.ng',
            fromName: 'BuildRight Construction Ltd',
            toAddresses: ['secretary@churchname.org'],
            ccAddresses: ['pastor@churchname.org'],
            subject: 'Re: Sanctuary Expansion Project - Phase 2 Quotation & Technical Drawings',
            body: 'Dear Church Secretary,\n\nFollowing our site inspection last week, we are pleased to submit the formal quotation and structural engineering drawings for the proposed Sanctuary Extension Phase 2.\n\nTotal Estimated Cost: ₦14,500,000.\nCompletion Timeline: 8 Weeks from mobilization.\n\nPlease review the attached invoice and project blueprint.',
            attachments: const [
              AttachmentItem(name: 'Sanctuary_Phase2_Quotation.pdf', size: 512000),
              AttachmentItem(name: 'Architectural_Blueprint.pdf', size: 1048576),
            ],
            createdAt: now.subtract(const Duration(days: 3)),
            createdBy: 'system',
            createdByName: 'BuildRight Consult',
            isRead: true,
          ),
          // Sent Sample 1
          FormalEmailModel(
            id: 'sample-sent-1',
            branchId: branchId,
            folder: EmailFolder.sent,
            fromAddress: 'secretary@churchname.org',
            fromName: 'Church Secretariat',
            toAddresses: ['headquarters@nationalchurchsynod.org'],
            ccAddresses: ['leadpastor@churchname.org'],
            subject: 'Official Transmission of Annual Branch Growth & Remittance Report',
            body: 'To the General Secretary,\nNational Church Synod Headquarters,\n\nGrace and peace be unto you.\n\nWe hereby formally submit our branch\'s Annual Progress Report, Financial Remittance Audit, and Membership Growth Census for the preceding ministry year.\n\nWe look forward to receiving your confirmation of receipt.\n\nYours in Christ,\nChurch Secretary',
            attachments: const [
              AttachmentItem(name: 'Annual_Branch_Report_2026.pdf', size: 380000),
            ],
            createdAt: now.subtract(const Duration(days: 5)),
            sentAt: now.subtract(const Duration(days: 5)),
            createdBy: 'user',
            createdByName: 'Church Secretary',
          ),
          // Draft Sample 1
          FormalEmailModel(
            id: 'sample-draft-1',
            branchId: branchId,
            folder: EmailFolder.draft,
            fromAddress: 'secretary@churchname.org',
            fromName: 'Church Secretariat',
            toAddresses: ['events@cityconventioncenter.com'],
            ccAddresses: ['pastor@churchname.org'],
            subject: 'Venue Reservation Request — Annual Easter Convention 2027',
            body: 'Dear Events Coordinator,\n\nWe are writing to inquire about venue availability and pricing for hosting our Annual Easter Conference at your facility from April 23rd to April 25th, 2027.\n\nWe anticipate an attendance of 2,500 delegates.',
            attachments: const [],
            createdAt: now.subtract(const Duration(hours: 4)),
            createdBy: 'user',
            createdByName: 'Church Secretary',
          ),
        ];

        for (final item in samples) {
          await _emailCol(branchId).doc(item.id).set(item.toFirestore());
        }
      }
    } catch (_) {}
  }
}
