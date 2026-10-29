import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/ui/painters/tube_painter.dart';
import 'package:aqua_sort_extreme/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pour Liquid Synchronization Widget Tests', () {
    late GameController controller;
    late GeneratedLevel level;

    setUp(() {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      level = generator.generate(777, settings);
      controller = GameController(initialLevel: level, levelNumber: 1);
    });

    void assertPaintedLiquidMatchesPuzzleState(WidgetTester tester, PuzzleState expectedState) {
      for (var i = 0; i < expectedState.tubeCount; i++) {
        final customPaintFinder = find.descendant(
          of: find.byKey(Key('tube_$i')),
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter as TubePainter;

        expect(
          painter.tube.units,
          equals(expectedState.tubes[i].units),
          reason: 'Tube $i painted units do not match PuzzleState units!',
        );
      }
    }

    testWidgets('Normal completed pour animation leaves painted liquid exactly equal to PuzzleState',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Find a legal move
      final legalMoves = controller.validator.legalMoves(controller.state.puzzleState);
      expect(legalMoves, isNotEmpty);
      final move = legalMoves.first;

      // Tap from tube then to tube
      await tester.tap(find.byKey(Key('tube_${move.from}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump();

      // Advance through pour animation to completion
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(controller.state.isInputLocked, isFalse);
      assertPaintedLiquidMatchesPuzzleState(tester, controller.state.puzzleState);
    });

    testWidgets('Skipped pour animation (tap mid-pour) immediately syncs painted liquid to PuzzleState',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      final legalMoves = controller.validator.legalMoves(controller.state.puzzleState);
      final move = legalMoves.first;

      // Start pour
      await tester.tap(find.byKey(Key('tube_${move.from}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump();

      // Advance slightly into pour
      await tester.pump(const Duration(milliseconds: 100));

      // Tap anywhere on the board to skip/fast-forward
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump();

      // Verify input is unlocked and painted liquid equals PuzzleState
      expect(controller.state.isInputLocked, isFalse);
      assertPaintedLiquidMatchesPuzzleState(tester, controller.state.puzzleState);
    });

    testWidgets('Undo mid-pour restores previous state and painted liquid matches PuzzleState',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      final initialPuzzleState = controller.state.puzzleState;
      final legalMoves = controller.validator.legalMoves(initialPuzzleState);
      final move = legalMoves.first;

      // Pour move 1
      await tester.tap(find.byKey(Key('tube_${move.from}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump();

      // Advance halfway through pour
      await tester.pump(const Duration(milliseconds: 180));

      // Tap board to skip finish pour
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump();

      // Now Undo
      await tester.tap(find.byKey(const Key('undo_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(controller.state.puzzleState, equals(initialPuzzleState));
      assertPaintedLiquidMatchesPuzzleState(tester, controller.state.puzzleState);
    });

    testWidgets('Invalid pour move leaves PuzzleState and painted liquid unchanged',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      final initialPuzzleState = controller.state.puzzleState;

      // Find an empty tube and tap it
      final emptyIndex = initialPuzzleState.tubes.indexWhere((t) => t.isEmpty);
      if (emptyIndex >= 0) {
        await tester.tap(find.byKey(Key('tube_$emptyIndex')));
        await tester.pump(const Duration(milliseconds: 300));

        expect(controller.state.selectedTubeIndex, isNull);
        expect(controller.state.puzzleState, equals(initialPuzzleState));
        assertPaintedLiquidMatchesPuzzleState(tester, controller.state.puzzleState);
      }
    });
  });
}

