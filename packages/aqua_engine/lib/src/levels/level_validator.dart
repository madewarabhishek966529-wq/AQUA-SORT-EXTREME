import '../model/move.dart';
import '../model/puzzle_state.dart';
import '../rules/move_validator.dart';
import 'generated_level.dart';

/// Result of replaying a solution through the game rules.
class ValidationResult {
  /// Whether all moves were legal and the final state is solved.
  final bool isValid;

  /// The final state reached after replay.
  final PuzzleState? finalState;

  /// Error message if validation failed.
  final String? errorMessage;

  /// The step index where failure occurred (0-indexed), if any.
  final int? failedStep;

  /// Number of moves replayed.
  final int stepCount;

  const ValidationResult._({
    required this.isValid,
    this.finalState,
    this.errorMessage,
    this.failedStep,
    required this.stepCount,
  });

  const ValidationResult.success({
    required PuzzleState finalState,
    required int stepCount,
  }) : this._(
          isValid: true,
          finalState: finalState,
          stepCount: stepCount,
        );

  const ValidationResult.failure({
    required String errorMessage,
    int? failedStep,
    PuzzleState? stateAtFailure,
    int stepCount = 0,
  }) : this._(
          isValid: false,
          errorMessage: errorMessage,
          failedStep: failedStep,
          finalState: stateAtFailure,
          stepCount: stepCount,
        );

  @override
  String toString() => isValid
      ? 'ValidationResult.success(steps: $stepCount)'
      : 'ValidationResult.failure(step: $failedStep, error: $errorMessage)';
}

/// Replays a level's stored solution through [MoveValidator] to verify correctness.
class LevelValidator {
  final MoveValidator validator;

  const LevelValidator({this.validator = const StandardMoveValidator()});

  /// Replays [level.solution] from [level.initial] and verifies it ends in a solved state.
  ValidationResult replay(GeneratedLevel level) {
    return replayMoves(level.initial, level.solution);
  }

  /// Replays a sequence of [moves] starting from [initial].
  ValidationResult replayMoves(PuzzleState initial, List<Move> moves) {
    var state = initial;
    for (var i = 0; i < moves.length; i++) {
      final move = moves[i];
      if (!validator.isLegal(state, move)) {
        return ValidationResult.failure(
          errorMessage: 'Illegal move at step $i: $move',
          failedStep: i,
          stateAtFailure: state,
          stepCount: i,
        );
      }
      state = validator.apply(state, move);
    }

    if (!state.isSolved) {
      return ValidationResult.failure(
        errorMessage: 'Replay completed but state is not solved: $state',
        failedStep: moves.length,
        stateAtFailure: state,
        stepCount: moves.length,
      );
    }

    return ValidationResult.success(
      finalState: state,
      stepCount: moves.length,
    );
  }
}
