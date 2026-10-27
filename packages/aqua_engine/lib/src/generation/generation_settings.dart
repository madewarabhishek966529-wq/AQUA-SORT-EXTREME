import 'package:meta/meta.dart';

/// Configuration settings for generating a level.
@immutable
class GenerationSettings {
  /// Number of distinct colors in the puzzle.
  final int numColors;

  /// Number of empty tubes provided.
  final int emptyTubes;

  /// Capacity of each tube (default 4).
  final int capacity;

  /// Target number of reverse-scramble steps.
  final int scrambleSteps;

  /// Minimum acceptable solution length after deduplication/simplification.
  final int minSolutionLength;

  /// Minimum acceptable fragmentation (average color changes per tube).
  final double minFragmentation;

  /// Generator algorithm version for determinism tracking.
  final int generatorVersion;

  /// Optional tier name.
  final String? tier;

  const GenerationSettings({
    required this.numColors,
    this.emptyTubes = 2,
    this.capacity = 4,
    required this.scrambleSteps,
    this.minSolutionLength = 8,
    this.minFragmentation = 0.5,
    this.generatorVersion = 1,
    this.tier,
  })  : assert(numColors >= 2, 'numColors must be >= 2'),
        assert(emptyTubes >= 1, 'emptyTubes must be >= 1'),
        assert(capacity >= 2, 'capacity must be >= 2'),
        assert(scrambleSteps >= 1, 'scrambleSteps must be >= 1');

  /// Total number of tubes in the generated puzzle.
  int get totalTubes => numColors + emptyTubes;

  /// Default preset for a given total tube count.
  factory GenerationSettings.forTubeCount(int totalTubes, {int? scrambleSteps}) {
    final empties = totalTubes <= 12 ? 2 : (totalTubes <= 30 ? 2 : 2);
    final colors = totalTubes - empties;
    // Scale steps according to difficulty metrics
    final steps = scrambleSteps ?? (colors * 3 + 10);
    final minLen = (steps * 0.4).round().clamp(6, 200);

    String tierName;
    if (totalTubes <= 12) {
      tierName = 'Beginner';
    } else if (totalTubes <= 20) {
      tierName = 'Intermediate';
    } else if (totalTubes <= 30) {
      tierName = 'Hard';
    } else if (totalTubes <= 40) {
      tierName = 'Expert';
    } else if (totalTubes <= 50) {
      tierName = 'Nightmare';
    } else {
      tierName = 'Impossible';
    }

    return GenerationSettings(
      numColors: colors,
      emptyTubes: empties,
      scrambleSteps: steps,
      minSolutionLength: minLen,
      minFragmentation: totalTubes >= 20 ? 0.8 : 0.4,
      tier: tierName,
    );
  }

  Map<String, dynamic> toJson() => {
        'numColors': numColors,
        'emptyTubes': emptyTubes,
        'capacity': capacity,
        'scrambleSteps': scrambleSteps,
        'minSolutionLength': minSolutionLength,
        'minFragmentation': minFragmentation,
        'generatorVersion': generatorVersion,
        if (tier != null) 'tier': tier,
      };

  factory GenerationSettings.fromJson(Map<String, dynamic> json) {
    return GenerationSettings(
      numColors: json['numColors'] as int,
      emptyTubes: json['emptyTubes'] as int? ?? 2,
      capacity: json['capacity'] as int? ?? 4,
      scrambleSteps: json['scrambleSteps'] as int,
      minSolutionLength: json['minSolutionLength'] as int? ?? 8,
      minFragmentation: (json['minFragmentation'] as num?)?.toDouble() ?? 0.5,
      generatorVersion: json['generatorVersion'] as int? ?? 1,
      tier: json['tier'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationSettings &&
        other.numColors == numColors &&
        other.emptyTubes == emptyTubes &&
        other.capacity == capacity &&
        other.scrambleSteps == scrambleSteps &&
        other.minSolutionLength == minSolutionLength &&
        other.minFragmentation == minFragmentation &&
        other.generatorVersion == generatorVersion &&
        other.tier == tier;
  }

  @override
  int get hashCode => Object.hash(
        numColors,
        emptyTubes,
        capacity,
        scrambleSteps,
        minSolutionLength,
        minFragmentation,
        generatorVersion,
        tier,
      );

  @override
  String toString() =>
      'GenerationSettings(colors: $numColors, empties: $emptyTubes, steps: $scrambleSteps, tier: $tier)';
}
