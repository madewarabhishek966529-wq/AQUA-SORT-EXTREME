import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController Tests', () {
    late GeneratedLevel level;
    late GameController controller;

    setUp(() {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      level = generator.generate(777, settings);
      controller = GameController(initialLevel: level, levelNumber: 1);
    });

    test('initial state is correct', () {
      expect(controller.state.puzzleState, equals(level.initial));
      expect(controller.state.moves, equals(0));
      expect(controller.state.history, isEmpty);
      expect(controller.state.selectedTubeIndex, isNull);
      expect(controller.state.isInputLocked, isFalse);
      expect(controller.state.isWon, isFalse);
    });

    test('select and deselect tube', () {
      // Find non-empty tube
      final nonEmptyIndex = controller.state.puzzleState.tubes.indexWhere((t) => t.isNotEmpty);
      expect(nonEmptyIndex, greaterThanOrEqualTo(0));

      // Select
      controller.selectTube(nonEmptyIndex);
      expect(controller.state.selectedTubeIndex, equals(nonEmptyIndex));

      // Deselect by tapping same tube again
      controller.selectTube(nonEmptyIndex);
      expect(controller.state.selectedTubeIndex, isNull);
    });

    test('tapping empty tube does not select it', () {
      final testLevel = GeneratedLevel(
        initial: PuzzleState([
          TubeState([1, 1, 1, 1]),
          TubeState.empty(),
        ]),
        solution: const [],
        seed: 1,
        settings: GenerationSettings.forTubeCount(8),
      );
      final testCtrl = GameController(initialLevel: testLevel);
      testCtrl.selectTube(1);
      expect(testCtrl.state.selectedTubeIndex, isNull);
      expect(testCtrl.state.shakingTubeIndex, equals(1));
    });

    test('valid pour updates state, increments moves, and pushes history', () {
      // Find a legal move from initial state
      const validator = StandardMoveValidator();
      final legalMoves = validator.legalMoves(controller.state.puzzleState);
      expect(legalMoves, isNotEmpty);

      final move = legalMoves.first;
      final priorState = controller.state.puzzleState;

      // Select from, then to
      controller.selectTube(move.from);
      expect(controller.state.selectedTubeIndex, equals(move.from));

      controller.selectTube(move.to);

      // Verify state was committed
      expect(controller.state.puzzleState, equals(validator.apply(priorState, move)));
      expect(controller.state.moves, equals(1));
      expect(controller.state.history.length, equals(1));
      expect(controller.state.history.first, equals(priorState));
      expect(controller.state.isInputLocked, isTrue); // input locked for animation
      expect(controller.state.selectedTubeIndex, isNull);
      expect(controller.state.activePourEvent, isNotNull);

      // Rapid tap during pour is ignored
      controller.selectTube(move.from);
      expect(controller.state.selectedTubeIndex, isNull); // still ignored!

      // Unlocking animation returns input to unlocked
      controller.unlockInput();
      expect(controller.state.isInputLocked, isFalse);
    });

    test('invalid pour leaves state unchanged and triggers shake', () {
      // Find two tubes with different top colors and non-empty
      final tubes = controller.state.puzzleState.tubes;
      int? fromIndex;
      int? toIndex;

      for (var i = 0; i < tubes.length; i++) {
        if (tubes[i].isNotEmpty) {
          for (var j = 0; j < tubes.length; j++) {
            if (i != j && tubes[j].isNotEmpty && tubes[i].topColor != tubes[j].topColor) {
              fromIndex = i;
              toIndex = j;
              break;
            }
          }
        }
        if (fromIndex != null) break;
      }

      if (fromIndex != null && toIndex != null) {
        final stateBefore = controller.state.puzzleState;

        controller.selectTube(fromIndex);
        controller.selectTube(toIndex);

        // State is completely unchanged
        expect(controller.state.puzzleState, equals(stateBefore));
        expect(controller.state.moves, equals(0));
        expect(controller.state.history, isEmpty);
        expect(controller.state.shakingTubeIndex, equals(toIndex));
      }
    });

    test('undo restores exact prior state and moves', () {
      const validator = StandardMoveValidator();
      final move = validator.legalMoves(controller.state.puzzleState).first;
      final original = controller.state.puzzleState;

      controller.selectTube(move.from);
      controller.selectTube(move.to);
      controller.unlockInput();

      expect(controller.state.moves, equals(1));
      expect(controller.state.puzzleState, isNot(equals(original)));

      // Undo
      controller.undo();
      expect(controller.state.puzzleState, equals(original));
      expect(controller.state.history, isEmpty);
      expect(controller.state.selectedTubeIndex, isNull);
    });

    test('restart resets state to initial configuration', () {
      const validator = StandardMoveValidator();
      final moves = validator.legalMoves(controller.state.puzzleState);
      if (moves.isNotEmpty) {
        controller.selectTube(moves.first.from);
        controller.selectTube(moves.first.to);
        controller.unlockInput();
      }

      controller.restart();
      expect(controller.state.puzzleState, equals(level.initial));
      expect(controller.state.moves, equals(0));
      expect(controller.state.history, isEmpty);
      expect(controller.state.isWon, isFalse);
    });

    test('integration test: replay full level through GameController to completion', () {
      // Play every move in level.solution through GameController
      for (var i = 0; i < level.solution.length; i++) {
        final move = level.solution[i];
        controller.selectTube(move.from);
        controller.selectTube(move.to);
        controller.unlockInput();
      }

      expect(controller.state.puzzleState.isSolved, isTrue);
      expect(controller.state.isWon, isTrue);
      expect(controller.state.moves, equals(level.solution.length));
    });
  });
}
