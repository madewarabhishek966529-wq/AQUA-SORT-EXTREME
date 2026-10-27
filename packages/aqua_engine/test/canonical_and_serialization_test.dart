import 'package:aqua_engine/aqua_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Canonicalization & Serialization', () {
    test('canonicalKey is invariant to tube permutations', () {
      final stateA = PuzzleState([
        TubeState([1, 2, 3, 4]),
        TubeState([2, 1, 4, 3]),
        TubeState.empty(),
        TubeState([3, 4, 1, 2]),
      ]);

      // Permuted order of the exact same tubes
      final stateB = PuzzleState([
        TubeState.empty(),
        TubeState([3, 4, 1, 2]),
        TubeState([1, 2, 3, 4]),
        TubeState([2, 1, 4, 3]),
      ]);

      expect(stateA.canonicalKey(), equals(stateB.canonicalKey()));

      // Different state produces different key
      final stateC = PuzzleState([
        TubeState([1, 2, 3, 4]),
        TubeState([2, 1, 4, 4]), // changed last unit
        TubeState.empty(),
        TubeState([3, 4, 1, 2]),
      ]);
      expect(stateA.canonicalKey(), isNot(equals(stateC.canonicalKey())));
    });

    test('PuzzleState compact encode/decode round-trip', () {
      final state = PuzzleState([
        TubeState([1, 2, 3, 4]),
        TubeState([2, 2]),
        TubeState.empty(),
        TubeState([3, 3, 3, 3]),
      ]);

      final encoded = state.encode();
      final decoded = PuzzleState.decode(encoded);
      expect(decoded, equals(state));
    });

    test('PuzzleState JSON round-trip', () {
      final state = PuzzleState([
        TubeState([1, 2, 3, 4]),
        TubeState([4, 3, 2, 1]),
        TubeState.empty(),
      ]);

      final json = state.toJson();
      final fromJson = PuzzleState.fromJson(json);
      expect(fromJson, equals(state));
    });

    test('Move JSON round-trip', () {
      const move = Move(from: 3, to: 7, count: 2, color: 4);
      final json = move.toJson();
      final fromJson = Move.fromJson(json);
      expect(fromJson, equals(move));
    });

    test('GenerationSettings JSON round-trip', () {
      const settings = GenerationSettings(
        numColors: 10,
        emptyTubes: 2,
        capacity: 4,
        scrambleSteps: 35,
        minSolutionLength: 15,
        minFragmentation: 0.8,
        generatorVersion: 1,
        tier: 'Intermediate',
      );

      final json = settings.toJson();
      final fromJson = GenerationSettings.fromJson(json);
      expect(fromJson, equals(settings));
    });

    test('GeneratedLevel JSON round-trip', () {
      const settings = GenerationSettings(
        numColors: 4,
        emptyTubes: 2,
        scrambleSteps: 15,
        minSolutionLength: 5,
        minFragmentation: 0.2,
      );
      final level = const PuzzleGenerator().generate(42, settings);

      final json = level.toJson();
      final fromJson = GeneratedLevel.fromJson(json);
      expect(fromJson, equals(level));
    });
  });
}
