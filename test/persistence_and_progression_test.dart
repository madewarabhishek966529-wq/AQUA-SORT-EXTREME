import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/achievement_manager.dart';
import 'package:aqua_sort_extreme/services/daily_challenge_service.dart';
import 'package:aqua_sort_extreme/services/save_repository.dart';
import 'package:aqua_sort_extreme/services/sqlite_save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 4 Persistence & Progression Tests', () {
    late SqliteSaveRepository repository;

    setUp(() async {
      repository = SqliteSaveRepository(customPath: inMemoryDatabasePath);
      await repository.init();
    });

    test('PlayerProgress save and load round-trip', () async {
      const progress = PlayerProgress(
        highestUnlockedLevel: 15,
        coins: 250,
        stars: 36,
      );

      await repository.saveProgress(progress);
      final loaded = await repository.loadProgress();

      expect(loaded.highestUnlockedLevel, equals(15));
      expect(loaded.coins, equals(250));
      expect(loaded.stars, equals(36));
    });

    test('LevelResult save and load round-trip', () async {
      final result = LevelResult(
        levelNumber: 7,
        bestMoves: 24,
        bestTimeSeconds: 58,
        stars: 3,
        completedAt: DateTime.utc(2026, 10, 27, 12, 0),
      );

      await repository.saveLevelResult(result);
      final loaded = await repository.loadLevelResult(7);

      expect(loaded, isNotNull);
      expect(loaded!.levelNumber, equals(7));
      expect(loaded.bestMoves, equals(24));
      expect(loaded.bestTimeSeconds, equals(58));
      expect(loaded.stars, equals(3));
      expect(loaded.completedAt, equals(result.completedAt));
    });

    test('PlayerStats save and load round-trip', () async {
      const stats = PlayerStats(
        totalSolved: 42,
        totalMoves: 850,
        totalPlayTimeSeconds: 3600,
        hintsUsed: 5,
        dailyCompleted: 4,
      );

      await repository.saveStats(stats);
      final loaded = await repository.loadStats();

      expect(loaded.totalSolved, equals(42));
      expect(loaded.totalMoves, equals(850));
      expect(loaded.totalPlayTimeSeconds, equals(3600));
      expect(loaded.hintsUsed, equals(5));
      expect(loaded.dailyCompleted, equals(4));
    });

    test('Continue after simulated kill: exact snapshot save and restore', () async {
      const generator = PuzzleGenerator();
      final settings = GenerationSettings.forTubeCount(8);
      final level = generator.generate(1234, settings);

      final controller = GameController(initialLevel: level);

      // Perform a couple of moves
      const validator = StandardMoveValidator();
      final moves = validator.legalMoves(controller.state.puzzleState);
      expect(moves, isNotEmpty);

      final move1 = moves.first;
      controller.selectTube(move1.from);
      controller.selectTube(move1.to);
      controller.unlockInput();
      controller.tickTimer();
      controller.tickTimer();

      // Snapshot the active session
      final snapshot = GameSnapshot(
        levelNumber: 1,
        currentState: controller.state.puzzleState,
        history: controller.state.history,
        elapsedSeconds: controller.state.elapsedSeconds,
        moves: controller.state.moves,
        timestamp: DateTime.now().toUtc(),
      );

      await repository.saveSnapshot(snapshot);

      // Simulate app kill and reopen: load snapshot from repository
      final restoredSnapshot = await repository.loadSnapshot();
      expect(restoredSnapshot, isNotNull);
      expect(restoredSnapshot!.levelNumber, equals(1));
      expect(restoredSnapshot.moves, equals(1));
      expect(restoredSnapshot.elapsedSeconds, equals(2));
      expect(restoredSnapshot.currentState, equals(controller.state.puzzleState));
      expect(restoredSnapshot.history.length, equals(1));
      expect(restoredSnapshot.history.first, equals(level.initial));

      // Test clear snapshot after level win
      await repository.clearSnapshot();
      expect(await repository.loadSnapshot(), isNull);
    });

    test('Daily challenge determinism: same UTC date produces identical puzzle', () {
      const service = DailyChallengeService();
      final dateA = DateTime.utc(2026, 11, 15, 8, 30);
      final dateB = DateTime.utc(2026, 11, 15, 23, 45); // same UTC day, different hours

      final levelA = service.getDailyLevel(dateA);
      final levelB = service.getDailyLevel(dateB);

      expect(levelA.seed, equals(levelB.seed));
      expect(levelA.initial, equals(levelB.initial));
      expect(levelA.solution, equals(levelB.solution));

      // Different day produces different puzzle
      final differentDay = DateTime.utc(2026, 11, 16);
      final levelDifferent = service.getDailyLevel(differentDay);
      expect(levelA.seed, isNot(equals(levelDifferent.seed)));
      expect(levelA.initial, isNot(equals(levelDifferent.initial)));
    });

    test('AchievementManager event triggers unlock and persist', () async {
      final manager = AchievementManager(repository: repository);
      await manager.init();

      expect(manager.isUnlocked('first_pour'), isFalse);
      expect(manager.isUnlocked('level_1_complete'), isFalse);

      // Trigger first pour
      await manager.onPour();
      expect(manager.isUnlocked('first_pour'), isTrue);

      // Trigger level win
      await manager.onLevelWon(
        levelNumber: 1,
        moves: 12,
        timeSeconds: 30,
        usedUndo: false,
        tier: 'Beginner',
      );

      expect(manager.isUnlocked('level_1_complete'), isTrue);
      expect(manager.isUnlocked('no_undo_win'), isTrue);
      expect(manager.isUnlocked('speed_demon'), isTrue);

      // Simulate restart: reloaded from database
      final manager2 = AchievementManager(repository: repository);
      await manager2.init();
      expect(manager2.isUnlocked('first_pour'), isTrue);
      expect(manager2.isUnlocked('level_1_complete'), isTrue);
      expect(manager2.isUnlocked('no_undo_win'), isTrue);
      expect(manager2.isUnlocked('speed_demon'), isTrue);
    });
  });
}
