import 'package:aqua_engine/aqua_engine.dart';
import 'package:test/test.dart';

void main() {
  const validator = StandardMoveValidator();

  group('MoveValidator', () {
    test('legal pour into empty tube transfers full top run', () {
      final state = PuzzleState([
        TubeState([1, 2, 2]),
        TubeState.empty(),
      ]);

      final move = validator.calculateMove(state, 0, 1);
      expect(move, isNotNull);
      expect(move!.from, equals(0));
      expect(move.to, equals(1));
      expect(move.count, equals(2));
      expect(move.color, equals(2));
      expect(validator.isLegal(state, move), isTrue);

      final next = validator.apply(state, move);
      expect(next.tubes[0].units, equals([1]));
      expect(next.tubes[1].units, equals([2, 2]));
    });

    test('partial group transfer when destination has limited space', () {
      final state = PuzzleState([
        TubeState([1, 3, 3, 3]), // 3 units of color 3 at top
        TubeState([3, 3, 3]),    // only 1 free space
      ]);

      final move = validator.calculateMove(state, 0, 1);
      expect(move, isNotNull);
      expect(move!.count, equals(1)); // only 1 fits!
      expect(move.color, equals(3));
      expect(validator.isLegal(state, move), isTrue);

      final next = validator.apply(state, move);
      expect(next.tubes[0].units, equals([1, 3, 3]));
      expect(next.tubes[1].units, equals([3, 3, 3, 3]));
      expect(next.tubes[1].isSolved, isTrue);
    });

    test('illegal moves rejected', () {
      final state = PuzzleState([
        TubeState([1, 2]),
        TubeState([3, 4]),
        TubeState.empty(),
        TubeState([5, 5, 5, 5]),
      ]);

      // Color mismatch: top 2 onto top 4
      expect(validator.isLegal(state, const Move(from: 0, to: 1, count: 1, color: 2)), isFalse);
      expect(validator.calculateMove(state, 0, 1), isNull);

      // From empty tube
      expect(validator.isLegal(state, const Move(from: 2, to: 0, count: 1, color: 1)), isFalse);
      expect(validator.calculateMove(state, 2, 0), isNull);

      // To full tube
      expect(validator.isLegal(state, const Move(from: 0, to: 3, count: 1, color: 2)), isFalse);
      expect(validator.calculateMove(state, 0, 3), isNull);

      // Self pour
      expect(validator.isLegal(state, const Move(from: 0, to: 0, count: 1, color: 2)), isFalse);
      expect(validator.calculateMove(state, 0, 0), isNull);

      // Out of bounds
      expect(validator.isLegal(state, const Move(from: -1, to: 1, count: 1, color: 2)), isFalse);
      expect(validator.isLegal(state, const Move(from: 0, to: 99, count: 1, color: 2)), isFalse);

      // Wrong count (claiming 2 when only 1 can pour)
      expect(validator.isLegal(state, const Move(from: 0, to: 2, count: 2, color: 2)), isFalse);

      // Applying illegal move throws ArgumentError
      expect(
        () => validator.apply(state, const Move(from: 0, to: 1, count: 1, color: 2)),
        throwsArgumentError,
      );
    });

    test('victory detection (isSolved)', () {
      final solvedState = PuzzleState([
        TubeState([1, 1, 1, 1]),
        TubeState([2, 2, 2, 2]),
        TubeState.empty(),
        TubeState.empty(),
      ]);
      expect(solvedState.isSolved, isTrue);

      final incompleteState = PuzzleState([
        TubeState([1, 1, 1]), // not full!
        TubeState([2, 2, 2, 2]),
        TubeState([1]),
        TubeState.empty(),
      ]);
      expect(incompleteState.isSolved, isFalse);

      final mixedState = PuzzleState([
        TubeState([1, 1, 1, 2]), // mixed!
        TubeState([2, 2, 2, 1]),
        TubeState.empty(),
      ]);
      expect(mixedState.isSolved, isFalse);
    });

    test('solver pruning skips pouring full single tube into empty tube', () {
      final state = PuzzleState([
        TubeState([1, 1, 1, 1]), // full mono
        TubeState([2, 2, 1]),    // partial
        TubeState.empty(), // empty 0
        TubeState.empty(), // empty 1
      ]);

      final allMoves = validator.legalMoves(state, solverPruning: false);
      final prunedMoves = validator.legalMoves(state, solverPruning: true);

      // Unpruned includes pouring tube 0 into empty 2 and empty 3
      expect(allMoves.any((m) => m.from == 0 && m.to == 2), isTrue);
      expect(allMoves.any((m) => m.from == 0 && m.to == 3), isTrue);

      // Pruned excludes pouring full mono tube 0 into empty tubes
      expect(prunedMoves.any((m) => m.from == 0 && (m.to == 2 || m.to == 3)), isFalse);

      // Pruned also breaks empty tube symmetry: only pours into the first empty tube (index 2)
      expect(prunedMoves.any((m) => m.from == 1 && m.to == 3), isFalse);
      expect(prunedMoves.any((m) => m.from == 1 && m.to == 2), isTrue);
    });
  });
}
