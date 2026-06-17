import 'package:cloud_firestore/cloud_firestore.dart';

class FcmAdminService {
  static Future<bool> sendNotification({
    required String title,
    required String content,
    DateTime? sendAfter,
    String topic = 'all',
  }) async {
    try {
      await FirebaseFirestore.instance.collection('push_notifications').add({
        'title': title,
        'body': content,
        'topic': topic,
        'sendAfter': sendAfter != null ? Timestamp.fromDate(sendAfter) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error saving notification request: $e');
      return false;
    }
  }
}
