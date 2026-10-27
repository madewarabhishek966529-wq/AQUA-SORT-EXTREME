import 'package:meta/meta.dart';

import 'tube_state.dart';

/// Represents the authoritative, immutable state of the puzzle board.
@immutable
class PuzzleState {
  /// The list of tubes, ordered by index (0-indexed).
  final List<TubeState> tubes;

  /// Default capacity for tubes in this puzzle.
  final int capacity;

  /// Creates a [PuzzleState]. The [tubes] iterable is copied and unmodifiable.
  PuzzleState(Iterable<TubeState> tubes, {this.capacity = 4})
      : tubes = List<TubeState>.unmodifiable(tubes) {
    if (this.tubes.isEmpty) {
      throw ArgumentError('A PuzzleState must have at least one tube');
    }
  }

  /// Number of tubes in the puzzle.
  int get tubeCount => tubes.length;

  /// Number of currently empty tubes.
  int get emptyTubeCount => tubes.where((t) => t.isEmpty).length;

  /// Number of completed, fully-sorted single-colored tubes.
  int get filledColorTubeCount =>
      tubes.where((t) => t.isFull && t.isSingleColor).length;

  /// Total count of liquid units across all tubes.
  int get totalUnits => tubes.fold<int>(0, (sum, t) => sum + t.units.length);

  /// Set of all distinct color IDs present in the puzzle.
  Set<int> get distinctColors => {
        for (final t in tubes) ...t.units,
      };

  /// Whether the puzzle is fully solved per ENGINE_SPEC:
  /// every tube is empty, or full and single-colored.
  bool get isSolved => tubes.every((t) => t.isSolved);

  /// Total color changes (transitions) across all tubes.
  int get totalColorChanges =>
      tubes.fold<int>(0, (sum, t) => sum + t.colorChanges);

  /// Average fragmentation: color transitions per non-empty tube.
  double get fragmentation {
    final nonEmpty = tubes.where((t) => t.isNotEmpty).length;
    if (nonEmpty == 0) return 0.0;
    return totalColorChanges / nonEmpty;
  }

  /// Returns a new [PuzzleState] with the tube at [index] replaced by [newTube].
  PuzzleState withTubeReplaced(int index, TubeState newTube) {
    if (index < 0 || index >= tubes.length) {
      throw RangeError.index(index, tubes, 'index');
    }
    final next = List<TubeState>.of(tubes);
    next[index] = newTube;
    return PuzzleState(next, capacity: capacity);
  }

  /// Canonical key for state memoization / visited sets.
  /// Tubes are sorted by their encoded contents so tube positions do not affect equivalence.
  String canonicalKey() {
    final encodedList = tubes.map((t) => t.encode()).toList()..sort();
    return encodedList.join(';');
  }

  /// Encodes the current puzzle state (preserving tube order) into a compact string:
  /// each tube separated by '|'.
  String encode() => tubes.map((t) => t.encode()).join('|');

  /// Decodes a puzzle state from compact format.
  factory PuzzleState.decode(String str, {int capacity = 4}) {
    final parts = str.split('|');
    return PuzzleState(
      parts.map((p) => TubeState.decode(p, capacity: capacity)),
      capacity: capacity,
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'capacity': capacity,
        'tubes': tubes.map((t) => t.toJson()).toList(),
      };

  /// Deserializes from a JSON map.
  factory PuzzleState.fromJson(Map<String, dynamic> json) {
    final cap = json['capacity'] as int? ?? 4;
    final list = json['tubes'] as List<dynamic>;
    return PuzzleState(
      list.map((raw) => TubeState.fromJson(raw, capacity: cap)),
      capacity: cap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PuzzleState) return false;
    if (capacity != other.capacity || tubes.length != other.tubes.length) {
      return false;
    }
    for (var i = 0; i < tubes.length; i++) {
      if (tubes[i] != other.tubes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var h = capacity;
    for (final t in tubes) {
      h = 0x1fffffff & (h * 31 + t.hashCode);
    }
    return h;
  }

  @override
  String toString() => 'PuzzleState(tubes: ${tubes.length}, solved: $isSolved)';
}
