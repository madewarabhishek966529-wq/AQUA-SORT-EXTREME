import 'package:meta/meta.dart';

/// Represents a single tube in Aqua Sort, holding liquid units from bottom to top.
@immutable
class TubeState {
  /// The color IDs of liquid units in this tube, from bottom (index 0) to top (last).
  final List<int> units;

  /// Maximum number of units this tube can hold.
  final int capacity;

  /// Creates a [TubeState]. The [units] list is defensively copied and made unmodifiable.
  TubeState(Iterable<int> units, {this.capacity = 4})
      : units = List<int>.unmodifiable(units) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be > 0');
    }
    if (this.units.length > capacity) {
      throw ArgumentError('Units length (${this.units.length}) exceeds capacity ($capacity)');
    }
  }

  /// Creates an empty tube with the specified [capacity].
  TubeState.empty({this.capacity = 4}) : units = const <int>[] {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be > 0');
    }
  }

  /// Whether the tube has no liquid.
  bool get isEmpty => units.isEmpty;

  /// Whether the tube has some liquid.
  bool get isNotEmpty => units.isNotEmpty;

  /// Whether the tube has reached its capacity.
  bool get isFull => units.length >= capacity;

  /// Number of free slots remaining in this tube.
  int get freeSpace => capacity - units.length;

  /// The color ID at the very top of the tube, or null if empty.
  int? get topColor => units.isEmpty ? null : units.last;

  /// The number of consecutive units at the top having [topColor].
  int get topColorCount {
    if (units.isEmpty) return 0;
    final target = units.last;
    var count = 0;
    for (var i = units.length - 1; i >= 0; i--) {
      if (units[i] == target) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Returns true if all liquid units currently in this tube share the same color.
  /// An empty tube is not considered single-color.
  bool get isSingleColor {
    if (units.isEmpty) return false;
    final first = units.first;
    for (var i = 1; i < units.length; i++) {
      if (units[i] != first) return false;
    }
    return true;
  }

  /// Per ENGINE_SPEC: a tube is solved if it is empty, or full and single-colored.
  bool get isSolved => isEmpty || (isFull && isSingleColor);

  /// Number of color boundary transitions from bottom to top.
  /// E.g. [1, 1, 2, 2] -> 1 change, [1, 2, 1, 2] -> 3 changes.
  int get colorChanges {
    if (units.length <= 1) return 0;
    var changes = 0;
    for (var i = 1; i < units.length; i++) {
      if (units[i] != units[i - 1]) {
        changes++;
      }
    }
    return changes;
  }

  /// Returns a new [TubeState] with the top [count] units removed.
  TubeState withPouredOut(int count) {
    if (count <= 0 || count > units.length) {
      throw ArgumentError.value(count, 'count', 'Must be between 1 and ${units.length}');
    }
    return TubeState(units.sublist(0, units.length - count), capacity: capacity);
  }

  /// Returns a new [TubeState] with [count] units of [color] added on top.
  TubeState withPouredIn(int color, int count) {
    if (count <= 0 || units.length + count > capacity) {
      throw ArgumentError.value(
        count,
        'count',
        'Cannot add $count units to tube of size ${units.length} with capacity $capacity',
      );
    }
    final next = List<int>.of(units)..addAll(Iterable.generate(count, (_) => color));
    return TubeState(next, capacity: capacity);
  }

  /// Compact string representation for canonical hashing: e.g. "1,2,3".
  String encode() => units.join(',');

  /// Decodes from compact string representation.
  factory TubeState.decode(String str, {int capacity = 4}) {
    final trimmed = str.trim();
    if (trimmed.isEmpty) {
      return TubeState.empty(capacity: capacity);
    }
    final parsed = trimmed.split(',').map(int.parse);
    return TubeState(parsed, capacity: capacity);
  }

  /// Serializes to a JSON-compatible list of integers.
  List<int> toJson() => units;

  /// Deserializes from a JSON-compatible list of integers.
  factory TubeState.fromJson(dynamic json, {int capacity = 4}) {
    if (json is List) {
      return TubeState(json.map((e) => e as int), capacity: capacity);
    }
    throw ArgumentError('Expected List<int> for TubeState, got: $json');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TubeState) return false;
    if (capacity != other.capacity || units.length != other.units.length) {
      return false;
    }
    for (var i = 0; i < units.length; i++) {
      if (units[i] != other.units[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var h = capacity;
    for (final u in units) {
      h = 0x1fffffff & (h * 31 + u);
    }
    return h;
  }

  @override
  String toString() => 'TubeState($units, cap: $capacity)';
}
