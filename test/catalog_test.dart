import 'dart:convert';
import 'dart:io';

import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3 Catalog & Hint Tests', () {
    test('catalog.json exists and contains 300 certified levels', () {
      final file = File('assets/levels/catalog.json');
      expect(file.existsSync(), isTrue);

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['totalLevels'], equals(300));

      final levels = json['levels'] as List<dynamic>;
      expect(levels.length, equals(300));

      final tierCounts = json['tierCounts'] as Map<String, dynamic>;
      expect(tierCounts['Beginner'], equals(50));
      expect(tierCounts['Intermediate'], equals(50));
      expect(tierCounts['Hard'], equals(50));
      expect(tierCounts['Expert'], equals(50));
      expect(tierCounts['Nightmare'], equals(50));
      expect(tierCounts['Impossible'], equals(50));
    });

    test('replays sample levels across all 6 tiers and confirms solved', () {
      final file = File('assets/levels/catalog.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final levels = json['levels'] as List<dynamic>;

      const validator = LevelValidator();

      // Sample 1 level from each tier (e.g. levels 1, 51, 101, 151, 201, 251)
      final sampleIndices = [0, 50, 100, 150, 200, 250];

      for (final index in sampleIndices) {
        final raw = levels[index] as Map<String, dynamic>;
        final initial = PuzzleState.fromJson(raw['initial'] as Map<String, dynamic>);
        final solution = (raw['solution'] as List<dynamic>)
            .map((m) => Move.fromJson(m as Map<String, dynamic>))
            .toList();

        final replay = validator.replayMoves(initial, solution);
        expect(
          replay.isValid,
          isTrue,
          reason: 'Failed for level ${raw['levelNumber']} (${raw['tier']}): ${replay.errorMessage}',
        );
        expect(replay.finalState!.isSolved, isTrue);
      }
    });

    test('GameController requestHint returns legal move and sets hintMove', () async {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      final level = generator.generate(333, settings);

      final controller = GameController(initialLevel: level);
      expect(controller.state.hintMove, isNull);

      await controller.requestHint();

      expect(controller.state.hintMove, isNotNull);
      const validator = StandardMoveValidator();
      expect(
        validator.isLegal(controller.state.puzzleState, controller.state.hintMove!),
        isTrue,
      );
    });
  });
}
