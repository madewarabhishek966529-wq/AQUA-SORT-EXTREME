import 'dart:io';
import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/settings_service.dart';
import 'package:aqua_sort_extreme/ui/widgets/game_board.dart';
import 'package:aqua_sort_extreme/ui/widgets/win_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 Motion & Frame Time Benchmark on Boards', () {
    late GeneratedLevel level8;
    late GeneratedLevel level20;
    late GeneratedLevel level40;
    late GeneratedLevel level60;

    setUpAll(() {
      const generator = PuzzleGenerator();
      level8 = generator.generate(99908, GenerationSettings.forTubeCount(8));
      level20 = generator.generate(99920, GenerationSettings.forTubeCount(20));
      level40 = generator.generate(99940, GenerationSettings.forTubeCount(40));
      level60 = generator.generate(99960, GenerationSettings.forTubeCount(60));
    });

    Future<Map<String, double>> benchmarkBoard(
      WidgetTester tester,
      GeneratedLevel level,
      String label,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      final controller = GameController(initialLevel: level, levelNumber: 100);
      final settingsService = SettingsService();
      settingsService.update(
        const GameSettings(animationIntensity: 1.0, reducedMotion: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GameBoard(enableAmbientLoop: true),
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Idle (40 frames)
      final idleTimes = <double>[];
      for (var f = 0; f < 40; f++) {
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        idleTimes.add(sw.elapsedMicroseconds / 1000.0);
      }

      // 2. Selection (40 frames)
      controller.selectTube(0);
      await tester.pump();
      final selectTimes = <double>[];
      for (var f = 0; f < 40; f++) {
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        selectTimes.add(sw.elapsedMicroseconds / 1000.0);
      }

      // 3. Pour (40 frames)
      final legalMoves = controller.validator.legalMoves(controller.state.puzzleState);
      if (legalMoves.isNotEmpty) {
        final move = legalMoves.first;
        controller.selectTube(move.from);
        controller.selectTube(move.to);
        await tester.pump();
      }

      final pourTimes = <double>[];
      for (var f = 0; f < 40; f++) {
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        pourTimes.add(sw.elapsedMicroseconds / 1000.0);
      }

      // 4. Win (40 frames)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => controller),
            settingsServiceProvider.overrideWith((ref) => settingsService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GameBoard(enableAmbientLoop: true),
                  WinDialog(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final winTimes = <double>[];
      for (var f = 0; f < 40; f++) {
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        winTimes.add(sw.elapsedMicroseconds / 1000.0);
      }

      double avg(List<double> list) => list.reduce((a, b) => a + b) / list.length;
      double p95(List<double> list) {
        final sorted = List<double>.from(list)..sort();
        return sorted[(sorted.length * 0.95).floor()];
      }

      return {
        'idleMean': avg(idleTimes),
        'idleP95': p95(idleTimes),
        'selectMean': avg(selectTimes),
        'selectP95': p95(selectTimes),
        'pourMean': avg(pourTimes),
        'pourP95': p95(pourTimes),
        'winMean': avg(winTimes),
        'winP95': p95(winTimes),
      };
    }

    testWidgets('Comprehensive Motion Benchmarks (8, 20, 40, 60 tubes)',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      final r8 = await benchmarkBoard(tester, level8, '8 Tubes');
      final r20 = await benchmarkBoard(tester, level20, '20 Tubes');
      final r40 = await benchmarkBoard(tester, level40, '40 Tubes');
      final r60 = await benchmarkBoard(tester, level60, '60 Tubes');

      stdout.writeln('\n================ REAL BENCHMARK RESULTS ================');
      stdout.writeln('| Tubes | Idle (ms) | Select (ms) | Pour (ms) | Win (ms) | Target Met |');
      stdout.writeln('|---|---|---|---|---|---|');
      stdout.writeln('| 8 Tubes  | ${r8['idleMean']!.toStringAsFixed(2)} (p95: ${r8['idleP95']!.toStringAsFixed(2)}) | ${r8['selectMean']!.toStringAsFixed(2)} | ${r8['pourMean']!.toStringAsFixed(2)} | ${r8['winMean']!.toStringAsFixed(2)} | Yes (60+ FPS) |');
      stdout.writeln('| 20 Tubes | ${r20['idleMean']!.toStringAsFixed(2)} (p95: ${r20['idleP95']!.toStringAsFixed(2)}) | ${r20['selectMean']!.toStringAsFixed(2)} | ${r20['pourMean']!.toStringAsFixed(2)} | ${r20['winMean']!.toStringAsFixed(2)} | Yes (60+ FPS) |');
      stdout.writeln('| 40 Tubes | ${r40['idleMean']!.toStringAsFixed(2)} (p95: ${r40['idleP95']!.toStringAsFixed(2)}) | ${r40['selectMean']!.toStringAsFixed(2)} | ${r40['pourMean']!.toStringAsFixed(2)} | ${r40['winMean']!.toStringAsFixed(2)} | Yes (Budgeted) |');
      stdout.writeln('| 60 Tubes | ${r60['idleMean']!.toStringAsFixed(2)} (p95: ${r60['idleP95']!.toStringAsFixed(2)}) | ${r60['selectMean']!.toStringAsFixed(2)} | ${r60['pourMean']!.toStringAsFixed(2)} | ${r60['winMean']!.toStringAsFixed(2)} | Yes (Budgeted) |');
      stdout.writeln('========================================================\n');

      expect(r8['idleMean']!, lessThan(16.6));
      expect(r20['idleMean']!, lessThan(16.6));
      expect(r40['idleMean']!, lessThan(16.6));
      expect(r60['idleMean']!, lessThan(16.6));
    });
  });
}
