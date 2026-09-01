import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns real-time stream of authoritative members created through CMS secretary/branch entry.
  Stream<List<Member>> getAllMembersStream() {
    return _firestore
        .collection('branches')
        .doc('default-branch')
        .collection('members')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Member.fromFirestore(d)).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Returns today's birthday and anniversary celebrants computed in real-time
  /// from the CMS branch member stream.
  Stream<List<Member>> getDailyCelebrantsStream() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return getAllMembersStream().map((members) {
      final celebrants = <Member>[];

      for (final member in members) {
        // Check birthday
        final bday = member.birthDate;
        if (bday != null && bday.month == today.month && bday.day == today.day) {
          celebrants.add(member);
          continue;
        }

        // Check wedding anniversary
        final wed = member.weddingDate;
        if (wed != null && wed.month == today.month && wed.day == today.day) {
          celebrants.add(member);
        }
      }

      return celebrants;
    });
  }

  Future<List<Member>> searchMembers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final snapshot = await _firestore
        .collection('branches')
        .doc('default-branch')
        .collection('members')
        .get();
    final list = snapshot.docs.map((d) => Member.fromFirestore(d)).toList();

    return list
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            (m.occupation?.toLowerCase().contains(q) ?? false) ||
            (m.profession?.toLowerCase().contains(q) ?? false) ||
            (m.email?.toLowerCase().contains(q) ?? false) ||
            (m.phoneNumber?.contains(q) ?? false) ||
            (m.stateOfOrigin?.toLowerCase().contains(q) ?? false))
        .take(20)
        .toList();
  }
}
