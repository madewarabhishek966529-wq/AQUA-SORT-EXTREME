import 'dart:math';

import 'package:aqua_engine/aqua_engine.dart';
import 'package:test/test.dart';

void main() {
  const generator = PuzzleGenerator();
  const validator = StandardMoveValidator();
  const levelValidator = LevelValidator();

  group('PuzzleGenerator', () {
    test('determinism: same seed and settings produce identical level', () {
      final settings = GenerationSettings.forTubeCount(8);
      final level1 = generator.generate(12345, settings);
      final level2 = generator.generate(12345, settings);

      expect(level1, equals(level2));
      expect(level1.initial, equals(level2.initial));
      expect(level1.solution, equals(level2.solution));
    });

    test('different seeds produce different levels', () {
      final settings = GenerationSettings.forTubeCount(8);
      final level1 = generator.generate(111, settings);
      final level2 = generator.generate(222, settings);

      expect(level1.initial, isNot(equals(level2.initial)));
    });

    test('generated level is not already solved', () {
      final settings = GenerationSettings.forTubeCount(12);
      final level = generator.generate(999, settings);

      expect(level.initial.isSolved, isFalse);
    });

    test('property test: reverse move preserves forward(reverse(S)) == S', () {
      // Create solved state
      const settings = GenerationSettings(
        numColors: 4,
        emptyTubes: 2,
        scrambleSteps: 10,
      );
      final solved = generator.createSolvedState(settings);

      // Take tube 0 ([1, 1, 1, 1]) and empty tube 4 ([])
      // rev(0 -> 4, j=2): tube 0 becomes [1, 1], tube 4 becomes [1, 1]
      final predState = PuzzleState([
        TubeState([1, 1]),
        solved.tubes[1],
        solved.tubes[2],
        solved.tubes[3],
        TubeState([1, 1]),
        solved.tubes[5],
      ]);

      // Forward move from tube 4 to tube 0 transfers 2 units of color 1
      const forwardMove = Move(from: 4, to: 0, count: 2, color: 1);
      expect(validator.isLegal(predState, forwardMove), isTrue);

      final reconstructed = validator.apply(predState, forwardMove);
      expect(reconstructed, equals(solved));
    });

    test('property test: for 50 random seeds, all generated levels replay to solved', () {
      final rng = Random(42);
      final tubeCounts = [8, 10, 12, 16, 20];

      for (var i = 0; i < 50; i++) {
        final totalTubes = tubeCounts[rng.nextInt(tubeCounts.length)];
        final seed = rng.nextInt(1000000);
        final settings = GenerationSettings.forTubeCount(totalTubes);

        final level = generator.generate(seed, settings);
        final result = levelValidator.replay(level);

        expect(
          result.isValid,
          isTrue,
          reason: 'Failed for seed $seed with tubes $totalTubes: ${result.errorMessage}',
        );
        expect(result.finalState!.isSolved, isTrue);
      }
    });

    test('DifficultyEvaluator classifies tiers correctly', () {
      const evaluator = DifficultyEvaluator();
      final settings8 = GenerationSettings.forTubeCount(8);
      final level8 = generator.generate(101, settings8);
      final metrics8 = evaluator.evaluate(level8);

      expect(metrics8.tier, equals('Beginner'));
      expect(metrics8.knownSolutionLength, greaterThanOrEqualTo(5));
      expect(metrics8.fragmentation, greaterThan(0.0));
      expect(metrics8.buriedDepth, greaterThan(0.0));
    });
  });
}
