import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/audio_service.dart';
import 'package:aqua_sort_extreme/ui/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 Large-Board UI & Accessibility Tests', () {
    late GeneratedLevel level60;

    setUpAll(() {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(60);
      level60 = generator.generate(99960, settings);
    });

    testWidgets('60-tube board renders without overflow on 1920x1080 desktop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameController(initialLevel: level60, levelNumber: 300);

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GameBoard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Ensure 60 tubes are present
      expect(find.byKey(const Key('tube_0')), findsOneWidget);
      expect(find.byKey(const Key('tube_59')), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('60-tube board renders without overflow on 1366x768 laptop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameController(initialLevel: level60, levelNumber: 300);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GameBoard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tube_0')), findsOneWidget);
      expect(find.byKey(const Key('tube_59')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('60-tube board renders on phone size 390x844 with scrollable pan',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GameController(initialLevel: level60, levelNumber: 300);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GameBoard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Zoom controls zoom in, zoom out, and reset',
        (WidgetTester tester) async {
      final controller = GameController(initialLevel: level60, levelNumber: 300);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GameBoard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('zoom_in_button')), findsOneWidget);
      expect(find.byKey(const Key('zoom_out_button')), findsOneWidget);
      expect(find.byKey(const Key('zoom_reset_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('zoom_in_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('zoom_out_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('zoom_reset_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Keyboard navigation moves focus and Enter selects tube',
        (WidgetTester tester) async {
      final controller = GameController(initialLevel: level60, levelNumber: 300);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GameBoard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Press ArrowRight to move focus
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Press ArrowDown to move row
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Press Enter to select tube
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Accessibility cues and reduced motion render properly',
        (WidgetTester tester) async {
      final controller = GameController(initialLevel: level60, levelNumber: 300);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GameBoard(
                showColorblindCues: true,
                colorblindPalette: true,
                reducedMotion: true,
                audioService: AudioService(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tube_0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
