import 'package:cms/src/features/communication/models/message_model.dart';
import 'package:cms/src/features/communication/models/communication_settings_model.dart';
import 'package:cms/src/features/communication/models/formal_email_model.dart';

abstract class CommunicationRepository {
  Stream<List<MessageModel>> watchMessages(String branchId);
  Future<void> saveMessage(String branchId, MessageModel message);
  Future<void> updateMessage(String branchId, MessageModel message);
  Future<CommunicationSettingsModel> getCommunicationSettings();
  Future<void> saveCommunicationSettings(CommunicationSettingsModel settings);

  Stream<List<FormalEmailModel>> watchFormalEmails(String branchId, EmailFolder folder);
  Future<void> saveFormalEmail(String branchId, FormalEmailModel email);
  Future<void> deleteFormalEmail(String branchId, String emailId);
}
