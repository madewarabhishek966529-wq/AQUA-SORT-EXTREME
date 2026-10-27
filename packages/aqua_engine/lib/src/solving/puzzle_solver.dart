import 'dart:async';
import 'dart:isolate';

import '../model/move.dart';
import '../model/puzzle_state.dart';
import '../rules/move_validator.dart';
import 'cancel_token.dart';
import 'solve_budget.dart';
import 'solve_result.dart';

/// Search node representing a state in the search space.
class _Node implements Comparable<_Node> {
  final PuzzleState state;
  final _Node? parent;
  final Move? move;
  final int g; // Cost from root (path length)
  final int h; // Heuristic estimate to solved state
  final double f; // Evaluation function f = g + weight * h

  const _Node({
    required this.state,
    this.parent,
    this.move,
    required this.g,
    required this.h,
    required this.f,
  });

  @override
  int compareTo(_Node other) {
    final diff = f.compareTo(other.f);
    if (diff != 0) return diff;
    return h.compareTo(other.h); // Tie-break with lower h
  }
}

/// Solves Aqua Sort puzzles using graph search with canonical state memoization,
/// solver pruning, and heuristic evaluation.
class PuzzleSolver {
  final MoveValidator validator;

  const PuzzleSolver({this.validator = const StandardMoveValidator()});

  /// Computes the documented heuristic h(state):
  /// Sum of color transitions plus penalties for incomplete or mixed tubes.
  /// h(state) == 0 iff state.isSolved.
  int computeHeuristic(PuzzleState state) {
    if (state.isSolved) return 0;
    var h = 0;
    for (final tube in state.tubes) {
      if (tube.isEmpty) continue;
      if (tube.isFull && tube.isSingleColor) continue;

      // Each color change requires at least 1-2 distinct pours to separate
      h += tube.colorChanges * 2;

      // Penalty for incomplete or mixed tube
      if (!tube.isSingleColor) {
        h += 2;
      } else if (!tube.isFull) {
        h += 1;
      }
    }
    return h;
  }

  /// Solves [state] within the limits defined by [budget].
  /// Runs synchronously on the current thread. To run in a background thread, use [solveInIsolate].
  SolveResult solve(
    PuzzleState state, {
    SolveBudget budget = const SolveBudget(),
    CancelToken? cancelToken,
  }) {
    final sw = Stopwatch()..start();

    if (state.isSolved) {
      return SolveResult.solved(
        path: const [],
        nodesExpanded: 0,
        elapsed: sw.elapsed,
      );
    }

    final visited = <String>{};
    final openQueue = _PriorityQueue<_Node>();

    final initialH = computeHeuristic(state);
    final root = _Node(
      state: state,
      g: 0,
      h: initialH,
      f: initialH.toDouble(),
    );

    openQueue.add(root);
    visited.add(state.canonicalKey());

    var nodesExpanded = 0;
    const heuristicWeight = 1.4; // Weighted A* for fast convergence on large boards

    while (openQueue.isNotEmpty) {
      // Check cancellation
      if (cancelToken != null && cancelToken.isCancelled) {
        sw.stop();
        return SolveResult.unverified(
          reason: 'Search cancelled by user',
          nodesExpanded: nodesExpanded,
          elapsed: sw.elapsed,
        );
      }

      // Check timeout
      if (nodesExpanded % 256 == 0 && sw.elapsed >= budget.timeout) {
        sw.stop();
        return SolveResult.unverified(
          reason: 'Search timeout (${budget.timeout.inMilliseconds}ms exceeded)',
          nodesExpanded: nodesExpanded,
          elapsed: sw.elapsed,
        );
      }

      // Check node limit
      if (nodesExpanded >= budget.maxNodes) {
        sw.stop();
        return SolveResult.unverified(
          reason: 'Node budget (${budget.maxNodes}) exceeded',
          nodesExpanded: nodesExpanded,
          elapsed: sw.elapsed,
        );
      }

      final current = openQueue.removeFirst();
      nodesExpanded++;

      // Goal check
      if (current.state.isSolved) {
        sw.stop();
        final path = _reconstructPath(current);
        return SolveResult.solved(
          path: path,
          nodesExpanded: nodesExpanded,
          elapsed: sw.elapsed,
        );
      }

      // Expand successor states using solver pruning
      final moves = validator.legalMoves(current.state, solverPruning: true);

      for (final move in moves) {
        // Avoid immediately reversing parent move
        if (current.move != null &&
            move.from == current.move!.to &&
            move.to == current.move!.from &&
            move.count == current.move!.count &&
            move.color == current.move!.color) {
          continue;
        }

        final nextState = validator.apply(current.state, move);
        final key = nextState.canonicalKey();

        if (visited.contains(key)) continue;
        visited.add(key);

        final nextH = computeHeuristic(nextState);
        final nextG = current.g + 1;
        final nextF = nextG + (nextH * heuristicWeight);

        openQueue.add(_Node(
          state: nextState,
          parent: current,
          move: move,
          g: nextG,
          h: nextH,
          f: nextF,
        ));
      }
    }

    // Queue exhausted completely: state space was fully searched
    sw.stop();
    return SolveResult.provenUnsolvable(
      nodesExpanded: nodesExpanded,
      elapsed: sw.elapsed,
    );
  }

  /// Runs the solver in a background [Isolate] so the main/UI thread never blocks.
  Future<SolveResult> solveInIsolate(
    PuzzleState state, {
    SolveBudget budget = const SolveBudget(),
  }) async {
    final stateJson = state.toJson();
    final budgetJson = budget.toJson();

    return Isolate.run<SolveResult>(() {
      final puzzleState = PuzzleState.fromJson(stateJson);
      final solveBudget = SolveBudget.fromJson(budgetJson);
      return const PuzzleSolver().solve(puzzleState, budget: solveBudget);
    });
  }

  List<Move> _reconstructPath(_Node target) {
    final path = <Move>[];
    _Node? curr = target;
    while (curr != null && curr.move != null) {
      path.add(curr.move!);
      curr = curr.parent;
    }
    return path.reversed.toList();
  }
}

/// Simple, efficient binary min-heap for priority queue.
class _PriorityQueue<E extends Comparable<E>> {
  final List<E> _heap = [];

  bool get isNotEmpty => _heap.isNotEmpty;
  int get length => _heap.length;

  void add(E element) {
    _heap.add(element);
    _siftUp(_heap.length - 1);
  }

  E removeFirst() {
    if (_heap.isEmpty) throw StateError('Queue is empty');
    final first = _heap.first;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _siftDown(0);
    }
    return first;
  }

  void _siftUp(int index) {
    var child = index;
    while (child > 0) {
      final parent = (child - 1) >> 1;
      if (_heap[child].compareTo(_heap[parent]) < 0) {
        final tmp = _heap[child];
        _heap[child] = _heap[parent];
        _heap[parent] = tmp;
        child = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int index) {
    var parent = index;
    final length = _heap.length;
    while (true) {
      final left = (parent << 1) + 1;
      final right = left + 1;
      var smallest = parent;

      if (left < length && _heap[left].compareTo(_heap[smallest]) < 0) {
        smallest = left;
      }
      if (right < length && _heap[right].compareTo(_heap[smallest]) < 0) {
        smallest = right;
      }

      if (smallest != parent) {
        final tmp = _heap[parent];
        _heap[parent] = _heap[smallest];
        _heap[smallest] = tmp;
        parent = smallest;
      } else {
        break;
      }
    }
  }
}
