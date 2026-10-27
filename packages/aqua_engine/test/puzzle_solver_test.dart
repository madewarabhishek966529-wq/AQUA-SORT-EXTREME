import 'package:aqua_engine/aqua_engine.dart';
import 'package:test/test.dart';

void main() {
  const solver = PuzzleSolver();
  const validator = StandardMoveValidator();
  const levelValidator = LevelValidator();

  group('PuzzleSolver Tests', () {
    test('solves already solved state in 0 steps', () {
      final state = PuzzleState([
        TubeState([1, 1, 1, 1]),
        TubeState([2, 2, 2, 2]),
        TubeState.empty(),
      ]);

      final result = solver.solve(state);
      expect(result, isA<Solved>());
      final solved = result as Solved;
      expect(solved.path, isEmpty);
      expect(solved.nodesExpanded, equals(0));
    });

    test('solves small 4-bottle puzzle and solution replays cleanly', () {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(6, scrambleSteps: 8);
      final level = generator.generate(42, settings);

      final result = solver.solve(level.initial, budget: const SolveBudget(maxNodes: 5000));
      expect(result, isA<Solved>());
      final solved = result as Solved;
      expect(solved.path, isNotEmpty);

      // Replay found solution
      final validation = levelValidator.replayMoves(level.initial, solved.path);
      expect(validation.isValid, isTrue);
      expect(validation.finalState!.isSolved, isTrue);
    });

    test('honors node budget and returns Unverified', () {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(16, scrambleSteps: 30);
      final level = generator.generate(999, settings);

      // Very low node budget
      final result = solver.solve(level.initial, budget: const SolveBudget(maxNodes: 10));
      expect(result, isA<Unverified>());
      final unverified = result as Unverified;
      expect(unverified.reason, contains('Node budget'));
    });

    test('honors cancellation token', () {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(12, scrambleSteps: 20);
      final level = generator.generate(123, settings);

      final token = CancelToken()..cancel();
      final result = solver.solve(level.initial, cancelToken: token);
      expect(result, isA<Unverified>());
      final unverified = result as Unverified;
      expect(unverified.reason, contains('cancelled'));
    });

    test('proves unsolvable when exhaustive search yields no solution', () {
      // Create a deadlocked state: 2 tubes full of alternating colors, 0 empty tubes
      final deadlocked = PuzzleState([
        TubeState([1, 2, 1, 2]),
        TubeState([2, 1, 2, 1]),
      ]);

      final result = solver.solve(deadlocked);
      expect(result, isA<ProvenUnsolvable>());
    });

    test('Isolate execution runs solver in background thread', () async {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(6, scrambleSteps: 6);
      final level = generator.generate(77, settings);

      final result = await solver.solveInIsolate(
        level.initial,
        budget: const SolveBudget(maxNodes: 3000),
      );
      expect(result, isA<Solved>());
      final solved = result as Solved;
      expect(levelValidator.replayMoves(level.initial, solved.path).isValid, isTrue);
    });
  });

  group('HintPlanner Tests', () {
    const hintPlanner = HintPlanner();

    test('returns legal progress hint and never undoes previous move', () async {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(6, scrambleSteps: 8);
      final level = generator.generate(505, settings);

      final hint = await hintPlanner.getHint(level.initial);
      expect(hint.isAvailable, isTrue);
      expect(hint.nextMove, isNotNull);
      expect(validator.isLegal(level.initial, hint.nextMove!), isTrue);

      // Now apply that move
      final nextState = validator.apply(level.initial, hint.nextMove!);
      // Ask for hint with previousMove specified
      final nextHint = await hintPlanner.getHint(nextState, previousMove: hint.nextMove!);
      expect(nextHint.isAvailable, isTrue);
      // Next hint must not simply undo the move just made
      final reverse = Move(
        from: hint.nextMove!.to,
        to: hint.nextMove!.from,
        count: hint.nextMove!.count,
        color: hint.nextMove!.color,
      );
      expect(nextHint.nextMove, isNot(equals(reverse)));
    });
  });
}
