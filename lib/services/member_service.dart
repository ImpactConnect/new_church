import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Member>> getDailyCelebrantsStream() {
    return _firestore.collection('daily_cache').doc('celebrants').snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      
      final data = snapshot.data()!;
      final List<dynamic> celebrantsList = data['celebrants'] ?? [];
      
      return celebrantsList.map((c) {
        final Map<String, dynamic> cMap = Map<String, dynamic>.from(c);
        return Member.fromJson(cMap, cMap['id'] ?? '');
      }).toList();
    });
  }

  Future<List<Member>> searchMembers(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Fetch all members and filter client-side for flexible search
    // (Firestore doesn't support multi-field text search natively)
    final snapshot = await _firestore
        .collection('branches')
        .doc('default-branch')
        .collection('members')
        .get();

    final q = query.trim().toLowerCase();
    return snapshot.docs
        .map((doc) => Member.fromFirestore(doc))
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            (m.occupation?.toLowerCase().contains(q) ?? false) ||
            (m.profession?.toLowerCase().contains(q) ?? false) ||
            (m.email?.toLowerCase().contains(q) ?? false) ||
            (m.phoneNumber?.contains(q) ?? false))
        .take(20)
        .toList();
  }
}
