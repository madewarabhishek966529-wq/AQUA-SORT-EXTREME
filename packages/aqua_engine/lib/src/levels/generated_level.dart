import 'package:meta/meta.dart';

import '../generation/generation_settings.dart';
import '../model/move.dart';
import '../model/puzzle_state.dart';

/// Represents a generated puzzle level carrying its initial scrambled state,
/// known verified solution, seed, and generation settings.
@immutable
class GeneratedLevel {
  /// The initial scrambled puzzle state presented to the player.
  final PuzzleState initial;

  /// Verified solution path leading from [initial] to a solved state.
  final List<Move> solution;

  /// The RNG seed used to generate this level.
  final int seed;

  /// The settings used during generation.
  final GenerationSettings settings;

  const GeneratedLevel({
    required this.initial,
    required this.solution,
    required this.seed,
    required this.settings,
  });

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'initial': initial.toJson(),
        'solution': solution.map((m) => m.toJson()).toList(),
        'seed': seed,
        'settings': settings.toJson(),
      };

  /// Deserializes from a JSON map.
  factory GeneratedLevel.fromJson(Map<String, dynamic> json) {
    return GeneratedLevel(
      initial: PuzzleState.fromJson(json['initial'] as Map<String, dynamic>),
      solution: (json['solution'] as List<dynamic>)
          .map((m) => Move.fromJson(m as Map<String, dynamic>))
          .toList(),
      seed: json['seed'] as int,
      settings: GenerationSettings.fromJson(
          json['settings'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GeneratedLevel) return false;
    if (seed != other.seed || settings != other.settings) return false;
    if (initial != other.initial) return false;
    if (solution.length != other.solution.length) return false;
    for (var i = 0; i < solution.length; i++) {
      if (solution[i] != other.solution[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(initial, Object.hashAll(solution), seed, settings);

  @override
  String toString() =>
      'GeneratedLevel(seed: $seed, tubes: ${initial.tubeCount}, solutionSteps: ${solution.length})';
}
