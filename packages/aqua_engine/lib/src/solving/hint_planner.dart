import '../model/move.dart';
import '../model/puzzle_state.dart';
import '../rules/move_validator.dart';
import 'puzzle_solver.dart';
import 'solve_budget.dart';
import 'solve_result.dart';

/// The result returned by [HintPlanner].
class HintResult {
  /// Whether a valid progress move was identified.
  final bool isAvailable;

  /// The immediate next move recommended to the player.
  final Move? nextMove;

  /// Up to 3-5 subsequent moves if a full path was solved.
  final List<Move> multiStepMoves;

  /// Human-readable explanation or status.
  final String message;

  const HintResult({
    required this.isAvailable,
    this.nextMove,
    this.multiStepMoves = const [],
    required this.message,
  });

  const HintResult.unavailable({String message = 'Hint unavailable'})
      : this(
          isAvailable: false,
          nextMove: null,
          multiStepMoves: const [],
          message: message,
        );

  const HintResult.available({
    required Move nextMove,
    List<Move> multiStepMoves = const [],
    String message = 'Recommended move found',
  }) : this(
          isAvailable: true,
          nextMove: nextMove,
          multiStepMoves: multiStepMoves,
          message: message,
        );

  @override
  String toString() => isAvailable
      ? 'HintResult.available($nextMove, steps: ${multiStepMoves.length})'
      : 'HintResult.unavailable($message)';
}

/// Provides intelligent move hints to the player by running search off the main thread.
class HintPlanner {
  final PuzzleSolver solver;
  final MoveValidator validator;

  const HintPlanner({
    this.solver = const PuzzleSolver(),
    this.validator = const StandardMoveValidator(),
  });

  /// Computes the best next move from [currentState].
  /// Never suggests undoing [previousMove].
  Future<HintResult> getHint(
    PuzzleState currentState, {
    Move? previousMove,
    SolveBudget budget = const SolveBudget.hint(),
  }) async {
    if (currentState.isSolved) {
      return const HintResult.unavailable(message: 'Level is already solved!');
    }

    // 1. Attempt solver search in isolate
    final solveResult = await solver.solveInIsolate(currentState, budget: budget);

    if (solveResult is Solved && solveResult.path.isNotEmpty) {
      var path = solveResult.path;

      // Filter out immediate undo of previous move if possible
      if (previousMove != null && path.isNotEmpty) {
        final first = path.first;
        if (_isReverseOf(first, previousMove)) {
          if (path.length > 1) {
            path = path.sublist(1);
          }
        }
      }

      final next = path.first;
      final multi = path.take(5).toList();

      return HintResult.available(
        nextMove: next,
        multiStepMoves: multi,
        message: 'Best path found (${path.length} steps remaining)',
      );
    }

    // 2. Fallback heuristic: find a legal progress move that strictly improves heuristic
    final legalMoves = validator.legalMoves(currentState, solverPruning: true);
    Move? bestProgressMove;
    var bestDelta = 0;

    final currentH = solver.computeHeuristic(currentState);

    for (final move in legalMoves) {
      if (previousMove != null && _isReverseOf(move, previousMove)) {
        continue; // Never suggest undoing previous move
      }

      final nextState = validator.apply(currentState, move);
      final nextH = solver.computeHeuristic(nextState);
      final delta = currentH - nextH; // positive delta means progress

      if (delta > bestDelta) {
        bestDelta = delta;
        bestProgressMove = move;
      }
    }

    if (bestProgressMove != null) {
      return HintResult.available(
        nextMove: bestProgressMove,
        multiStepMoves: [bestProgressMove],
        message: 'Progress move found',
      );
    }

    return const HintResult.unavailable(
      message: 'Hint unavailable within current budget',
    );
  }

  bool _isReverseOf(Move a, Move b) {
    return a.from == b.to && a.to == b.from && a.color == b.color;
  }
}
