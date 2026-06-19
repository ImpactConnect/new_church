import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCategory {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  VideoCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory VideoCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoCategory(
      id: doc.id,
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}
