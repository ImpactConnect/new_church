import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for undo/redo functionality
class UndoRedoState {
  final List<String> undoStack;
  final List<String> redoStack;
  final int maxStackSize;

  const UndoRedoState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.maxStackSize = 50,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  UndoRedoState copyWith({
    List<String>? undoStack,
    List<String>? redoStack,
  }) {
    return UndoRedoState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      maxStackSize: maxStackSize,
    );
  }
}

/// State notifier for managing undo/redo operations
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  UndoRedoNotifier() : super(const UndoRedoState());

  /// Pushes current state to undo stack
  void pushState(String content) {
    final newUndoStack = [...state.undoStack, content];
    
    // Limit stack size
    if (newUndoStack.length > state.maxStackSize) {
      newUndoStack.removeAt(0);
    }

    state = state.copyWith(
      undoStack: newUndoStack,
      redoStack: [], // Clear redo stack on new change
    );
  }

  /// Undoes the last change and returns the previous state
  String? undo() {
    if (!state.canUndo) return null;

    final undoStack = List<String>.from(state.undoStack);
    final lastState = undoStack.removeLast();

    final redoStack = [...state.redoStack, lastState];

    state = state.copyWith(
      undoStack: undoStack,
      redoStack: redoStack,
    );

    return undoStack.isNotEmpty ? undoStack.last : null;
  }

  /// Redoes the last undone change and returns the state
  String? redo() {
    if (!state.canRedo) return null;

    final redoStack = List<String>.from(state.redoStack);
    final stateToRestore = redoStack.removeLast();

    final undoStack = [...state.undoStack, stateToRestore];

    state = state.copyWith(
      undoStack: undoStack,
      redoStack: redoStack,
    );

    return stateToRestore;
  }

  /// Clears all undo/redo history
  void clear() {
    state = const UndoRedoState();
  }
}
