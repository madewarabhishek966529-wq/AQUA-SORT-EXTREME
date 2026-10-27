import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/save_repository.dart';
import 'pour_event.dart';

/// State of the active game session.
class GameState {
  final PuzzleState puzzleState;
  final List<PuzzleState> history;
  final int? selectedTubeIndex;
  final int moves;
  final int elapsedSeconds;
  final bool isWon;
  final bool isInputLocked;
  final int? shakingTubeIndex;
  final PourEvent? activePourEvent;
  final GeneratedLevel currentLevel;
  final int levelNumber;
  final bool autoPour;
  final Move? hintMove;
  final bool isCalculatingHint;
  final String? hintMessage;

  const GameState({
    required this.puzzleState,
    required this.history,
    this.selectedTubeIndex,
    required this.moves,
    required this.elapsedSeconds,
    required this.isWon,
    required this.isInputLocked,
    this.shakingTubeIndex,
    this.activePourEvent,
    required this.currentLevel,
    required this.levelNumber,
    this.autoPour = true,
    this.hintMove,
    this.isCalculatingHint = false,
    this.hintMessage,
  });

  GameState copyWith({
    PuzzleState? puzzleState,
    List<PuzzleState>? history,
    int? selectedTubeIndex,
    bool clearSelected = false,
    int? moves,
    int? elapsedSeconds,
    bool? isWon,
    bool? isInputLocked,
    int? shakingTubeIndex,
    bool clearShaking = false,
    PourEvent? activePourEvent,
    bool clearActivePour = false,
    GeneratedLevel? currentLevel,
    int? levelNumber,
    bool? autoPour,
    Move? hintMove,
    bool clearHint = false,
    bool? isCalculatingHint,
    String? hintMessage,
    bool clearHintMessage = false,
  }) {
    return GameState(
      puzzleState: puzzleState ?? this.puzzleState,
      history: history ?? this.history,
      selectedTubeIndex:
          clearSelected ? null : (selectedTubeIndex ?? this.selectedTubeIndex),
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isWon: isWon ?? this.isWon,
      isInputLocked: isInputLocked ?? this.isInputLocked,
      shakingTubeIndex:
          clearShaking ? null : (shakingTubeIndex ?? this.shakingTubeIndex),
      activePourEvent:
          clearActivePour ? null : (activePourEvent ?? this.activePourEvent),
      currentLevel: currentLevel ?? this.currentLevel,
      levelNumber: levelNumber ?? this.levelNumber,
      autoPour: autoPour ?? this.autoPour,
      hintMove: clearHint ? null : (hintMove ?? this.hintMove),
      isCalculatingHint: isCalculatingHint ?? this.isCalculatingHint,
      hintMessage: clearHintMessage ? null : (hintMessage ?? this.hintMessage),
    );
  }
}

/// Riverpod StateNotifier managing gameplay intents and transitions.
class GameController extends StateNotifier<GameState> {
  final MoveValidator validator;
  int _eventIdCounter = 0;

  GameController({
    required GeneratedLevel initialLevel,
    int levelNumber = 1,
    this.validator = const StandardMoveValidator(),
  }) : super(
          GameState(
            puzzleState: initialLevel.initial,
            history: const [],
            moves: 0,
            elapsedSeconds: 0,
            isWon: initialLevel.initial.isSolved,
            isInputLocked: false,
            currentLevel: initialLevel,
            levelNumber: levelNumber,
          ),
        );

  /// Player intent: tap a tube at [index].
  void selectTube(int index) {
    if (state.isInputLocked || state.isWon) return;
    if (index < 0 || index >= state.puzzleState.tubeCount) return;

    final from = state.selectedTubeIndex;

    // No tube currently selected
    if (from == null) {
      if (state.puzzleState.tubes[index].isEmpty) {
        // Can't pour from an empty tube
        state = state.copyWith(shakingTubeIndex: index);
        return;
      }
      state = state.copyWith(selectedTubeIndex: index, clearShaking: true);
      return;
    }

    // Tapping the already selected tube deselects it
    if (from == index) {
      state = state.copyWith(clearSelected: true, clearShaking: true);
      return;
    }

    // Attempting a pour from `from` to `index`
    final move = validator.calculateMove(state.puzzleState, from, index);
    if (move == null) {
      // Invalid move
      state = state.copyWith(shakingTubeIndex: index);
      return;
    }

    // Valid move:
    // 1. Commit new state to puzzleState
    final nextState = validator.apply(state.puzzleState, move);
    final isNowWon = nextState.isSolved;
    final eventId = ++_eventIdCounter;
    final pourEvent = PourEvent(
      from: from,
      to: index,
      count: move.count,
      color: move.color,
      eventId: eventId,
    );

    state = state.copyWith(
      puzzleState: nextState,
      history: [...state.history, state.puzzleState],
      moves: state.moves + 1,
      isWon: isNowWon,
      isInputLocked: true,
      clearSelected: true,
      clearShaking: true,
      activePourEvent: pourEvent,
    );
  }

  /// Called by animation controller when liquid transfer animation finishes or is skipped.
  void unlockInput() {
    state = state.copyWith(
      isInputLocked: false,
      clearActivePour: true,
      clearShaking: true,
    );
  }

  /// Restores previous state from undo stack.
  void undo() {
    if (state.isInputLocked || state.history.isEmpty) return;

    final prev = state.history.last;
    final newHistory = state.history.sublist(0, state.history.length - 1);

    state = state.copyWith(
      puzzleState: prev,
      history: newHistory,
      isWon: prev.isSolved,
      clearSelected: true,
      clearShaking: true,
      clearActivePour: true,
      isInputLocked: false,
    );
  }

  /// Restarts current level to initial configuration.
  void restart() {
    if (state.isInputLocked) return;

    state = state.copyWith(
      puzzleState: state.currentLevel.initial,
      history: const [],
      moves: 0,
      isWon: false,
      clearSelected: true,
      clearShaking: true,
      clearActivePour: true,
      isInputLocked: false,
    );
  }

  /// Loads a new level.
  void loadLevel(int levelNumber, GeneratedLevel level) {
    state = GameState(
      puzzleState: level.initial,
      history: const [],
      moves: 0,
      elapsedSeconds: 0,
      isWon: level.initial.isSolved,
      isInputLocked: false,
      currentLevel: level,
      levelNumber: levelNumber,
      autoPour: state.autoPour,
    );
  }

  /// Timer tick (e.g. every second).
  void tickTimer() {
    if (!state.isWon) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    }
  }

  /// Clears shaking state after shake animation concludes.
  void clearShaking() {
    if (state.shakingTubeIndex != null) {
      state = state.copyWith(clearShaking: true);
    }
  }

  /// Asynchronously calculates and highlights a hint move using HintPlanner.
  Future<void> requestHint() async {
    if (state.isCalculatingHint || state.isInputLocked || state.isWon) return;

    state = state.copyWith(isCalculatingHint: true, clearHint: true);

    const hintPlanner = HintPlanner();
    final hint = await hintPlanner.getHint(state.puzzleState);

    if (hint.isAvailable && hint.nextMove != null) {
      state = state.copyWith(
        hintMove: hint.nextMove,
        isCalculatingHint: false,
        hintMessage: hint.message,
      );
    } else {
      state = state.copyWith(
        clearHint: true,
        isCalculatingHint: false,
        hintMessage: hint.message,
      );
    }
  }

  /// Clears active hint.
  void clearHint() {
    state = state.copyWith(clearHint: true, clearHintMessage: true);
  }

  /// Restores an in-progress game state from a saved snapshot.
  void restoreSnapshot(GameSnapshot snapshot) {
    state = state.copyWith(
      puzzleState: snapshot.currentState,
      history: snapshot.history,
      moves: snapshot.moves,
      elapsedSeconds: snapshot.elapsedSeconds,
      isWon: snapshot.currentState.isSolved,
      levelNumber: snapshot.levelNumber,
      clearSelected: true,
      clearShaking: true,
      clearActivePour: true,
      clearHint: true,
      clearHintMessage: true,
      isInputLocked: false,
    );
  }
}

/// Helper Riverpod provider for gameController.
final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  // Default Level 1: 8 tubes Beginner level
  const generator = PuzzleGenerator();
  final settings = GenerationSettings.forTubeCount(8);
  final level1 = generator.generate(1001, settings);

  return GameController(initialLevel: level1, levelNumber: 1);
});
