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
    
    final snapshot = await _firestore
        .collection('members')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList();
  }
}
