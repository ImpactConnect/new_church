import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_tile_model.dart';
import '../models/home_template_config.dart';

class HomeTemplateRepository {
  HomeTemplateRepository._();

  static final HomeTemplateRepository instance = HomeTemplateRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of the active template ID from `app_settings/ui_config`.
  /// When admin changes it, the app reacts instantly.
  Stream<String> get activeTemplateIdStream => _db
      .collection('app_settings')
      .doc('ui_config')
      .snapshots()
      .map((snap) {
        if (!snap.exists) return HomeTemplateId.classic;
        return (snap.data()?['activeHomeTemplate'] as String?) ??
            HomeTemplateId.classic;
      });

  /// Stream of tiles for a given template, sorted by [sortOrder].
  Stream<List<HomeTileModel>> tilesStream(String templateId) => _db
      .collection('home_templates')
      .doc(templateId)
      .collection('tiles')
      .where('isActive', isEqualTo: true)
      .orderBy('sortOrder')
      .snapshots()
      .map((snap) =>
          snap.docs.map(HomeTileModel.fromFirestore).toList());

  /// Fetch all tiles once (for admin editing).
  Future<List<HomeTileModel>> fetchAllTiles(String templateId) async {
    final snap = await _db
        .collection('home_templates')
        .doc(templateId)
        .collection('tiles')
        .orderBy('sortOrder')
        .get();
    return snap.docs.map(HomeTileModel.fromFirestore).toList();
  }

  /// Create a new tile.
  Future<void> createTile(String templateId, HomeTileModel tile) async {
    await _db
        .collection('home_templates')
        .doc(templateId)
        .collection('tiles')
        .add(tile.toFirestore());
  }

  /// Update an existing tile.
  Future<void> updateTile(String templateId, HomeTileModel tile) async {
    await _db
        .collection('home_templates')
        .doc(templateId)
        .collection('tiles')
        .doc(tile.id)
        .update(tile.toFirestore());
  }

  /// Delete a tile.
  Future<void> deleteTile(String templateId, String tileId) async {
    await _db
        .collection('home_templates')
        .doc(templateId)
        .collection('tiles')
        .doc(tileId)
        .delete();
  }

  /// Set the active template from the admin panel.
  Future<void> setActiveTemplate(String templateId) async {
    await _db.collection('app_settings').doc('ui_config').set(
      {'activeHomeTemplate': templateId},
      SetOptions(merge: true),
    );
  }

  /// Ensure the Firestore template document exists.
  Future<void> ensureTemplateDoc(String templateId, String name) async {
    final ref = _db.collection('home_templates').doc(templateId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
