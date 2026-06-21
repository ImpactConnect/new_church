import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ai/chat_session_model.dart';

part 'chat_session_repository.g.dart';

/// Firestore-backed chat session store for AI Bible chat.
@Riverpod(keepAlive: true)
class ChatSessionRepository extends _$ChatSessionRepository {
  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('bible_ai_chats')
        .doc(user.uid)
        .collection('sessions');
  }

  @override
  List<ChatSessionModel> build() {
    // We intentionally do not await this in build so it initializes synchronously.
    // The UI will update when state changes.
    _loadFromFirestore();
    return [];
  }

  Future<void> _loadFromFirestore() async {
    final col = _collection;
    if (col == null) return;

    try {
      final snapshot = await col.orderBy('updatedAt', descending: true).get();
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ChatSessionModel.fromFirestore(data);
      }).toList();
      state = sessions;
    } catch (e) {
      // Handle error silently for now
    }
  }

  void addSession(ChatSessionModel session) {
    if (session.id == null || session.id!.isEmpty) {
      session.id = FirebaseFirestore.instance.collection('tmp').doc().id; // generate temp ID
    }
    state = [session, ...state];
    saveSession(session);
  }

  Future<List<ChatSessionModel>> getAllSessions() async {
    if (state.isEmpty && FirebaseAuth.instance.currentUser != null) {
      await _loadFromFirestore();
    }
    return state;
  }

  Future<void> saveSession(ChatSessionModel session) async {
    final col = _collection;
    if (col == null) return; // Cannot persist without user

    session.updatedAt = DateTime.now();
    session.createdAt ??= DateTime.now();

    try {
      if (session.id == null || session.id!.isEmpty) {
        final docRef = col.doc();
        session.id = docRef.id;
      }
      await col.doc(session.id).set(session.toFirestore());

      // Update local state to ensure it has the correct ID/timestamps
      final index = state.indexWhere((s) => s.id == session.id);
      if (index >= 0) {
        final newState = [...state];
        newState[index] = session;
        state = newState;
      } else {
        state = [session, ...state];
      }
    } catch (e) {
      // Failed to persist
    }
  }

  Future<void> deleteSession(String id) async {
    state = state.where((s) => s.id != id).toList();

    final col = _collection;
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (e) {
      // Handle error
    }
  }

  void clearSessions() {
    state = [];
  }
}
