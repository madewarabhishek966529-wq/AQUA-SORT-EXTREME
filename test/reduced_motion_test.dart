import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/settings_service.dart';
import 'package:aqua_sort_extreme/ui/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reduced Motion & Animation Off Widget Tests', () {
    late GameController controller;

    setUp(() {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      final level = generator.generate(888, settings);
      controller = GameController(initialLevel: level, levelNumber: 1);
    });

    testWidgets('With reducedMotion on, no looping controllers run and 0 particles spawn',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final settingsService = SettingsService();
      settingsService.update(
        const GameSettings(reducedMotion: true, animationIntensity: 0.0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GameBoard(
                reducedMotion: true,
                enableAmbientLoop: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Verify board rendered
      expect(find.byKey(const Key('tube_0')), findsOneWidget);

      // 2. Perform a pour to test that it is instantaneous without lingering loopers
      final legalMoves = controller.validator.legalMoves(controller.state.puzzleState);
      final move = legalMoves.first;

      await tester.tap(find.byKey(Key('tube_${move.from}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('tube_${move.to}')));
      await tester.pump(const Duration(milliseconds: 50));

      // With reduced motion, input unlocks immediately (instant transfer)
      expect(controller.state.isInputLocked, isFalse);

      // 3. Verify that pumpAndSettle finishes immediately with no infinite looping tickers
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('With reducedMotion on, win condition produces no particle bursts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Construct an already-solved level
      final solvedState = PuzzleState([
        TubeState([1, 1, 1, 1]),
        TubeState([2, 2, 2, 2]),
        TubeState.empty(),
        TubeState.empty(),
      ]);

      final wonLevel = GeneratedLevel(
        seed: 9999,
        settings: GenerationSettings.forTubeCount(4),
        initial: solvedState,
        solution: const [],
      );

      final wonController = GameController(initialLevel: wonLevel, levelNumber: 1);
      final settingsService = SettingsService();
      settingsService.update(const GameSettings(reducedMotion: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => wonController),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GameBoard(
                reducedMotion: true,
                enableAmbientLoop: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // pumpAndSettle must complete immediately without running victory particle tickers
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
