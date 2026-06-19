import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/testimony.dart';

class TestimonyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Testimony>> getTestimoniesStream() {
    return _firestore
        .collection('testimonies')
        .orderBy('dateShared', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Testimony.fromFirestore(doc)).toList(),
        );
  }
}
