import '../model/puzzle_state.dart';
import '../rules/move_validator.dart';
import 'generated_level.dart';

/// Difficulty metrics computed for a level as defined in DIFFICULTY_METRICS.md.
class LevelMetrics {
  final int knownSolutionLength;
  final double emptyRatio;
  final double fragmentation;
  final double buriedDepth;
  final int initialBranching;
  final double avgBranching;
  final String tier;

  const LevelMetrics({
    required this.knownSolutionLength,
    required this.emptyRatio,
    required this.fragmentation,
    required this.buriedDepth,
    required this.initialBranching,
    required this.avgBranching,
    required this.tier,
  });

  Map<String, dynamic> toJson() => {
        'knownSolutionLength': knownSolutionLength,
        'emptyRatio': emptyRatio,
        'fragmentation': fragmentation,
        'buriedDepth': buriedDepth,
        'initialBranching': initialBranching,
        'avgBranching': avgBranching,
        'tier': tier,
      };

  factory LevelMetrics.fromJson(Map<String, dynamic> json) => LevelMetrics(
        knownSolutionLength: json['knownSolutionLength'] as int,
        emptyRatio: (json['emptyRatio'] as num).toDouble(),
        fragmentation: (json['fragmentation'] as num).toDouble(),
        buriedDepth: (json['buriedDepth'] as num).toDouble(),
        initialBranching: json['initialBranching'] as int,
        avgBranching: (json['avgBranching'] as num).toDouble(),
        tier: json['tier'] as String,
      );

  @override
  String toString() =>
      'LevelMetrics(tier: $tier, len: $knownSolutionLength, frag: ${fragmentation.toStringAsFixed(2)}, depth: ${buriedDepth.toStringAsFixed(2)})';
}

/// Evaluates difficulty metrics and assigns tiers to puzzle levels.
class DifficultyEvaluator {
  final MoveValidator validator;

  const DifficultyEvaluator({this.validator = const StandardMoveValidator()});

  /// Evaluates all metrics for [level].
  LevelMetrics evaluate(GeneratedLevel level) {
    final state = level.initial;
    final totalTubes = state.tubeCount;
    final emptyRatio = state.emptyTubeCount / totalTubes;
    final fragmentation = state.fragmentation;
    final buriedDepth = _computeBuriedDepth(state);
    final initialBranching = validator.legalMoves(state).length;
    final avgBranching = _computeAvgBranching(level);
    final tier = classifyTier(totalTubes, level.solution.length, fragmentation);

    return LevelMetrics(
      knownSolutionLength: level.solution.length,
      emptyRatio: emptyRatio,
      fragmentation: fragmentation,
      buriedDepth: buriedDepth,
      initialBranching: initialBranching,
      avgBranching: avgBranching,
      tier: tier,
    );
  }

  /// Calculates average depth of the deepest (last-needed) unit of each color from the top.
  double _computeBuriedDepth(PuzzleState state) {
    final colors = state.distinctColors;
    if (colors.isEmpty) return 0.0;

    var sumDepth = 0;
    for (final color in colors) {
      var maxDepthForColor = 0;
      for (final tube in state.tubes) {
        final len = tube.units.length;
        for (var i = 0; i < len; i++) {
          if (tube.units[i] == color) {
            final depthFromTop = len - 1 - i;
            if (depthFromTop > maxDepthForColor) {
              maxDepthForColor = depthFromTop;
            }
          }
        }
      }
      sumDepth += maxDepthForColor;
    }

    return sumDepth / colors.length;
  }

  /// Calculates the average number of legal moves along the solution trajectory.
  double _computeAvgBranching(GeneratedLevel level) {
    var state = level.initial;
    var totalBranching = validator.legalMoves(state).length;

    for (final move in level.solution) {
      if (!validator.isLegal(state, move)) break;
      state = validator.apply(state, move);
      totalBranching += validator.legalMoves(state).length;
    }

    return totalBranching / (level.solution.length + 1);
  }

  /// Maps tube count and metrics to tier name per DIFFICULTY_METRICS.md.
  String classifyTier(int totalTubes, int solutionLength, double fragmentation) {
    if (totalTubes <= 12) {
      return 'Beginner';
    } else if (totalTubes <= 20) {
      return 'Intermediate';
    } else if (totalTubes <= 30) {
      return 'Hard';
    } else if (totalTubes <= 40) {
      return 'Expert';
    } else if (totalTubes <= 50) {
      return 'Nightmare';
    } else {
      return 'Impossible';
    }
  }
}
