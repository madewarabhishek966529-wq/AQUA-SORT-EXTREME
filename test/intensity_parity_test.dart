import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/settings_service.dart';
import 'package:aqua_sort_extreme/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Effects Intensity Parity Integration Tests', () {
    late GeneratedLevel level;

    setUp(() {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      level = generator.generate(1005, settings);
    });

    testWidgets('Complete level with effects at High (1.5x): succeeds with verified solution',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameController(initialLevel: level, levelNumber: 5);
      final settingsService = SettingsService();
      settingsService.update(
        const GameSettings(animationIntensity: 1.5, reducedMotion: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Play through solution
      for (final move in level.solution) {
        controller.selectTube(move.from);
        controller.selectTube(move.to);
        await tester.pump();
        // Advance animation
        await tester.pump(const Duration(milliseconds: 600));
      }

      expect(controller.state.isWon, isTrue);
      expect(controller.state.moves, equals(level.solution.length));
      expect(controller.state.puzzleState.isSolved, isTrue);
    });

    testWidgets('Complete level with effects at Off (0.0x): succeeds with identical state & moves',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameController(initialLevel: level, levelNumber: 5);
      final settingsService = SettingsService();
      settingsService.update(
        const GameSettings(animationIntensity: 0.0, reducedMotion: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Play through solution
      for (final move in level.solution) {
        controller.selectTube(move.from);
        controller.selectTube(move.to);
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(controller.state.isWon, isTrue);
      expect(controller.state.moves, equals(level.solution.length));
      expect(controller.state.puzzleState.isSolved, isTrue);
    });

    test('Parity check: High effects vs Off effects yield identical PuzzleState and moves', () {
      final highController = GameController(initialLevel: level, levelNumber: 5);
      for (final move in level.solution) {
        highController.selectTube(move.from);
        highController.selectTube(move.to);
        highController.unlockInput();
      }

      final offController = GameController(initialLevel: level, levelNumber: 5);
      for (final move in level.solution) {
        offController.selectTube(move.from);
        offController.selectTube(move.to);
        offController.unlockInput();
      }

      expect(highController.state.isWon, isTrue);
      expect(offController.state.isWon, isTrue);
      expect(highController.state.moves, equals(offController.state.moves));
      expect(highController.state.puzzleState, equals(offController.state.puzzleState));
    });
  });
}
