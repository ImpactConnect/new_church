import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/ai/exegesis_session_model.dart';
import 'package:church_mobile/features/bible_ai/features/bible/providers/bible_providers.dart';
import '../repositories/exegesis_repository.dart';

part 'exegesis_providers.g.dart';

@riverpod
ExegesisRepository exegesisRepository(ExegesisRepositoryRef ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ExegesisRepository(
    aiService: aiService,
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
Stream<List<ExegesisSession>> recentExegesisSessions(RecentExegesisSessionsRef ref) {
  final repo = ref.watch(exegesisRepositoryProvider);
  return repo.watchSessions();
}
