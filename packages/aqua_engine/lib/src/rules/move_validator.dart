import 'dart:math';

import '../model/move.dart';
import '../model/puzzle_state.dart';

/// Contract for move legality and state transition.
abstract class MoveValidator {
  /// Returns true if [move] is valid to execute on [state].
  bool isLegal(PuzzleState state, Move move);

  /// Applies [move] to [state] and returns the resulting [PuzzleState].
  /// Throws [ArgumentError] if the move is illegal.
  PuzzleState apply(PuzzleState state, Move move);

  /// Computes all legal forward moves from [state].
  /// If [solverPruning] is true, prunes redundant moves (e.g. pouring full single-colored
  /// tube into an empty tube, and duplicate pours into multiple empty tubes).
  List<Move> legalMoves(PuzzleState state, {bool solverPruning = false});

  /// Computes the exact [Move] if transferring from [from] to [to] is legal,
  /// or null if the transfer is invalid.
  Move? calculateMove(PuzzleState state, int from, int to);
}

/// Standard rule implementation matching ENGINE_SPEC.
class StandardMoveValidator implements MoveValidator {
  const StandardMoveValidator();

  @override
  bool isLegal(PuzzleState state, Move move) {
    if (move.from < 0 || move.from >= state.tubeCount) return false;
    if (move.to < 0 || move.to >= state.tubeCount) return false;
    if (move.from == move.to) return false;

    final fromTube = state.tubes[move.from];
    final toTube = state.tubes[move.to];

    if (fromTube.isEmpty) return false;
    if (toTube.freeSpace <= 0) return false;

    final color = fromTube.topColor!;
    if (toTube.isNotEmpty && toTube.topColor != color) return false;

    final run = fromTube.topColorCount;
    final transferCount = min(run, toTube.freeSpace);

    return move.count == transferCount && move.color == color;
  }

  @override
  PuzzleState apply(PuzzleState state, Move move) {
    if (!isLegal(state, move)) {
      throw ArgumentError('Illegal move: $move for state: $state');
    }

    final newFrom = state.tubes[move.from].withPouredOut(move.count);
    final newTo = state.tubes[move.to].withPouredIn(move.color, move.count);

    final nextTubes = List.of(state.tubes);
    nextTubes[move.from] = newFrom;
    nextTubes[move.to] = newTo;

    return PuzzleState(nextTubes, capacity: state.capacity);
  }

  @override
  Move? calculateMove(PuzzleState state, int from, int to) {
    if (from < 0 || from >= state.tubeCount) return null;
    if (to < 0 || to >= state.tubeCount) return null;
    if (from == to) return null;

    final fromTube = state.tubes[from];
    final toTube = state.tubes[to];

    if (fromTube.isEmpty) return null;
    if (toTube.freeSpace <= 0) return null;

    final color = fromTube.topColor!;
    if (toTube.isNotEmpty && toTube.topColor != color) return null;

    final run = fromTube.topColorCount;
    final count = min(run, toTube.freeSpace);

    return Move(from: from, to: to, count: count, color: color);
  }

  @override
  List<Move> legalMoves(PuzzleState state, {bool solverPruning = false}) {
    final result = <Move>[];
    final tubeCount = state.tubeCount;

    // For solver pruning: symmetry reduction across multiple empty tubes.
    int? firstEmptyTubeIndex;
    if (solverPruning) {
      for (var i = 0; i < tubeCount; i++) {
        if (state.tubes[i].isEmpty) {
          firstEmptyTubeIndex = i;
          break;
        }
      }
    }

    for (var from = 0; from < tubeCount; from++) {
      final fromTube = state.tubes[from];
      if (fromTube.isEmpty) continue;

      // Solver pruning: pouring a full single-colored tube achieves nothing.
      if (solverPruning && fromTube.isFull && fromTube.isSingleColor) {
        continue;
      }

      final color = fromTube.topColor!;
      final run = fromTube.topColorCount;

      for (var to = 0; to < tubeCount; to++) {
        if (from == to) continue;
        final toTube = state.tubes[to];
        if (toTube.freeSpace <= 0) continue;
        if (toTube.isNotEmpty && toTube.topColor != color) continue;

        if (solverPruning && toTube.isEmpty) {
          // Only pour into the first empty tube to break symmetry.
          if (to != firstEmptyTubeIndex) continue;
          // Pouring a mono-colored tube into an empty tube just renames the tube.
          if (fromTube.isSingleColor) continue;
        }

        final count = min(run, toTube.freeSpace);
        result.add(Move(from: from, to: to, count: count, color: color));
      }
    }

    return result;
  }
}
