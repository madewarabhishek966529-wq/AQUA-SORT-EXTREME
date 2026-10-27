import 'package:meta/meta.dart';

/// Represents a liquid transfer move from one tube to another.
@immutable
class Move {
  /// Index of the source tube.
  final int from;

  /// Index of the destination tube.
  final int to;

  /// Number of units poured.
  final int count;

  /// Color ID of the units poured.
  final int color;

  const Move({
    required this.from,
    required this.to,
    required this.count,
    required this.color,
  });

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'count': count,
        'color': color,
      };

  /// Deserializes from a JSON map.
  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      from: json['from'] as int,
      to: json['to'] as int,
      count: json['count'] as int,
      color: json['color'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Move &&
        other.from == from &&
        other.to == to &&
        other.count == count &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(from, to, count, color);

  @override
  String toString() => 'Move($from -> $to, count: $count, color: $color)';
}
