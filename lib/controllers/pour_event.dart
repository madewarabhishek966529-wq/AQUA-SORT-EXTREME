import 'package:flutter/foundation.dart';

/// Event emitted when a valid pour is committed to state.
/// Contains all parameters required for [PourAnimationController] to animate the liquid.
@immutable
class PourEvent {
  final int from;
  final int to;
  final int count;
  final int color;
  final int eventId;

  const PourEvent({
    required this.from,
    required this.to,
    required this.count,
    required this.color,
    required this.eventId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PourEvent &&
          other.eventId == eventId &&
          other.from == from &&
          other.to == to &&
          other.count == count &&
          other.color == color;

  @override
  int get hashCode => Object.hash(eventId, from, to, count, color);

  @override
  String toString() =>
      'PourEvent(id: $eventId, $from -> $to, count: $count, color: $color)';
}
