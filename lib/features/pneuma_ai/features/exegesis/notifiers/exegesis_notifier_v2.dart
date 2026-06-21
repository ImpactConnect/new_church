import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exegesis_result_v2_model.dart';
import '../repositories/exegesis_repository_v2.dart';
import '../services/exegesis_ai_service_v2.dart';

/// State for exegesis generation and mode switching
class ExegesisState {
  final ExegesisResultV2? result;
  final bool isLoading;
  final String? error;
  final bool isSwitchingMode;

  const ExegesisState({
    this.result,
    this.isLoading = false,
    this.error,
    this.isSwitchingMode = false,
  });

  ExegesisState copyWith({
    ExegesisResultV2? result,
    bool? isLoading,
    String? error,
    bool? isSwitchingMode,
  }) {
    return ExegesisState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSwitchingMode: isSwitchingMode ?? this.isSwitchingMode,
    );
  }
}

/// Notifier for managing exegesis generation and mode switching
class ExegesisNotifier extends StateNotifier<ExegesisState> {
  final ExegesisAiServiceV2 _aiService;
  final ExegesisRepositoryV2 _repository;

  ExegesisNotifier(this._aiService, this._repository) 
      : super(const ExegesisState());

  /// Generate a new exegesis
  Future<void> generateExegesis({
    required String subject,
    required ExegesisEntryType entryType,
    required ExegesisMode mode,
    String? verseText,
    String translation = 'ESV',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _aiService.generateExegesis(
        subject: subject,
        entryType: entryType,
        mode: mode,
        verseText: verseText,
        translation: translation,
      );

      await _repository.save(result);
      state = state.copyWith(result: result, isLoading: false);
    } catch (e, st) {
      print('Error generating exegesis: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Switch to alternate mode (Understand ↔ Go Deep)
  Future<void> switchMode(ExegesisMode targetMode) async {
    final current = state.result;
    if (current == null) return;
    if (current.mode == targetMode) return;

    // Check if alternate mode is cached
    final cachedAlternate = await _repository.getAlternateMode(current.id, targetMode);
    if (cachedAlternate != null) {
      // Instant switch (< 100ms)
      state = state.copyWith(result: cachedAlternate);
      return;
    }

    // Generate new mode
    state = state.copyWith(isSwitchingMode: true, error: null);
    try {
      final alternate = await _aiService.generateAlternateMode(
        existingResult: current,
        targetMode: targetMode,
      );

      // Cache the alternate mode in both directions
      await _repository.cacheAlternateMode(current.id, alternate);
      
      state = state.copyWith(
        result: alternate,
        isSwitchingMode: false,
      );
    } catch (e, st) {
      print('Error switching mode: $e\n$st');
      state = state.copyWith(
        isSwitchingMode: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Load an existing exegesis by ID
  Future<void> loadById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getById(id);
      if (result != null) {
        state = state.copyWith(result: result, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Exegesis not found',
        );
      }
    } catch (e, st) {
      print('Error loading exegesis: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Delete the current exegesis
  Future<void> deleteCurrent() async {
    final current = state.result;
    if (current == null) return;

    try {
      await _repository.delete(current.id);
      state = const ExegesisState();
    } catch (e, st) {
      print('Error deleting exegesis: $e\n$st');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear the current state
  void clear() {
    state = const ExegesisState();
  }
}
