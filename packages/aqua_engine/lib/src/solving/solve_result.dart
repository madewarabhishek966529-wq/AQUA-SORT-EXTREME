import '../model/move.dart';

/// Sealed hierarchy representing the outcome of a puzzle search.
abstract class SolveResult {
  final int nodesExpanded;
  final Duration elapsed;

  const SolveResult({
    required this.nodesExpanded,
    required this.elapsed,
  });

  /// Factory constructor for successful solve.
  factory SolveResult.solved({
    required List<Move> path,
    required int nodesExpanded,
    required Duration elapsed,
  }) = Solved;

  /// Factory constructor when search hit budget, timeout, or cancellation.
  factory SolveResult.unverified({
    required String reason,
    required int nodesExpanded,
    required Duration elapsed,
  }) = Unverified;

  /// Factory constructor ONLY when search exhausted all reachable states without finding a solution.
  factory SolveResult.provenUnsolvable({
    required int nodesExpanded,
    required Duration elapsed,
  }) = ProvenUnsolvable;

  bool get isSolved => this is Solved;
  bool get isUnverified => this is Unverified;
  bool get isProvenUnsolvable => this is ProvenUnsolvable;

  Map<String, dynamic> toJson();
}

/// A solution path was successfully found.
class Solved extends SolveResult {
  final List<Move> path;

  const Solved({
    required this.path,
    required int nodesExpanded,
    required Duration elapsed,
  }) : super(nodesExpanded: nodesExpanded, elapsed: elapsed);

  @override
  Map<String, dynamic> toJson() => {
        'status': 'solved',
        'path': path.map((m) => m.toJson()).toList(),
        'nodesExpanded': nodesExpanded,
        'elapsedMs': elapsed.inMilliseconds,
      };

  @override
  String toString() =>
      'Solved(steps: ${path.length}, nodes: $nodesExpanded, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Search hit a budget limit, timeout, or was cancelled before proving solvability.
class Unverified extends SolveResult {
  final String reason;

  const Unverified({
    required this.reason,
    required int nodesExpanded,
    required Duration elapsed,
  }) : super(nodesExpanded: nodesExpanded, elapsed: elapsed);

  @override
  Map<String, dynamic> toJson() => {
        'status': 'unverified',
        'reason': reason,
        'nodesExpanded': nodesExpanded,
        'elapsedMs': elapsed.inMilliseconds,
      };

  @override
  String toString() =>
      'Unverified(reason: $reason, nodes: $nodesExpanded, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// The state space was exhaustively searched and no solution exists.
class ProvenUnsolvable extends SolveResult {
  const ProvenUnsolvable({
    required int nodesExpanded,
    required Duration elapsed,
  }) : super(nodesExpanded: nodesExpanded, elapsed: elapsed);

  @override
  Map<String, dynamic> toJson() => {
        'status': 'proven_unsolvable',
        'nodesExpanded': nodesExpanded,
        'elapsedMs': elapsed.inMilliseconds,
      };

  @override
  String toString() =>
      'ProvenUnsolvable(nodes: $nodesExpanded, elapsed: ${elapsed.inMilliseconds}ms)';
}
