import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exegesis_result_v2_model.dart';
import '../repositories/exegesis_repository_v2.dart';
import '../services/exegesis_ai_service_v2.dart';
import '../notifiers/exegesis_notifier_v2.dart';
import '../../bible/providers/bible_providers.dart';
import '../../../data/repositories/prompt_repository.dart';

// Prompt Repository provider
final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository();
});

// Repository provider
final exegesisRepositoryV2Provider = Provider<ExegesisRepositoryV2>((ref) {
  return ExegesisRepositoryV2Impl(
    firestore: FirebaseFirestore.instance,
  );
});

// AI Service provider
final exegesisAiServiceV2Provider = Provider<ExegesisAiServiceV2>((ref) {
  return ExegesisAiServiceV2(
    aiService: ref.watch(aiServiceProvider),
    promptRepo: ref.watch(promptRepositoryProvider),
  );
});

// Current result provider
final currentExegesisResultProvider = StateProvider<ExegesisResultV2?>((ref) => null);

// Current mode provider
final currentExegesisModeProvider = StateProvider<ExegesisMode>((ref) => ExegesisMode.understand);

// History provider
final exegesisHistoryProvider = FutureProvider<List<ExegesisResultV2>>((ref) async {
  final repo = ref.watch(exegesisRepositoryV2Provider);
  return repo.getAll();
});

// History stream provider
final exegesisHistoryStreamProvider = StreamProvider<List<ExegesisResultV2>>((ref) {
  final repo = ref.watch(exegesisRepositoryV2Provider);
  return repo.watchAll();
});

// Notifier provider
final exegesisNotifierProvider = StateNotifierProvider<ExegesisNotifier, ExegesisState>((ref) {
  return ExegesisNotifier(
    ref.watch(exegesisAiServiceV2Provider),
    ref.watch(exegesisRepositoryV2Provider),
  );
});
