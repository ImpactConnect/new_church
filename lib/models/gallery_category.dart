import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryCategory {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  GalleryCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory GalleryCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryCategory(
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
