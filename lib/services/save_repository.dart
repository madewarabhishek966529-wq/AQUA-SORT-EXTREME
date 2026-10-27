import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/foundation.dart';

/// Player progression data: unlocked levels, stars, coins.
@immutable
class PlayerProgress {
  final int highestUnlockedLevel;
  final int coins;
  final int stars;

  const PlayerProgress({
    this.highestUnlockedLevel = 1,
    this.coins = 100,
    this.stars = 0,
  });

  Map<String, dynamic> toJson() => {
        'highestUnlockedLevel': highestUnlockedLevel,
        'coins': coins,
        'stars': stars,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) => PlayerProgress(
        highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
        coins: json['coins'] as int? ?? 100,
        stars: json['stars'] as int? ?? 0,
      );
}

/// Recorded score for a completed level.
@immutable
class LevelResult {
  final int levelNumber;
  final int bestMoves;
  final int bestTimeSeconds;
  final int stars; // 1, 2, or 3
  final DateTime completedAt;

  const LevelResult({
    required this.levelNumber,
    required this.bestMoves,
    required this.bestTimeSeconds,
    required this.stars,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'bestMoves': bestMoves,
        'bestTimeSeconds': bestTimeSeconds,
        'stars': stars,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
        levelNumber: (json['levelNumber'] ?? json['level_number']) as int,
        bestMoves: (json['bestMoves'] ?? json['best_moves']) as int,
        bestTimeSeconds: (json['bestTimeSeconds'] ??
            json['best_time'] ??
            json['best_time_seconds']) as int,
        stars: json['stars'] as int,
        completedAt: DateTime.parse(
            (json['completedAt'] ?? json['completed_at']) as String),
      );
}

/// In-progress game snapshot for exact suspend and resume.
@immutable
class GameSnapshot {
  final int levelNumber;
  final PuzzleState currentState;
  final List<PuzzleState> history;
  final int elapsedSeconds;
  final int moves;
  final DateTime timestamp;

  const GameSnapshot({
    required this.levelNumber,
    required this.currentState,
    required this.history,
    required this.elapsedSeconds,
    required this.moves,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'currentState': currentState.toJson(),
        'history': history.map((s) => s.toJson()).toList(),
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) => GameSnapshot(
        levelNumber: json['levelNumber'] as int,
        currentState:
            PuzzleState.fromJson(json['currentState'] as Map<String, dynamic>),
        history: (json['history'] as List<dynamic>)
            .map((s) => PuzzleState.fromJson(s as Map<String, dynamic>))
            .toList(),
        elapsedSeconds: json['elapsedSeconds'] as int,
        moves: json['moves'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Cumulative lifetime player statistics.
@immutable
class PlayerStats {
  final int totalSolved;
  final int totalMoves;
  final int totalPlayTimeSeconds;
  final int hintsUsed;
  final int dailyCompleted;

  const PlayerStats({
    this.totalSolved = 0,
    this.totalMoves = 0,
    this.totalPlayTimeSeconds = 0,
    this.hintsUsed = 0,
    this.dailyCompleted = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalSolved': totalSolved,
        'totalMoves': totalMoves,
        'totalPlayTimeSeconds': totalPlayTimeSeconds,
        'hintsUsed': hintsUsed,
        'dailyCompleted': dailyCompleted,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        totalSolved: json['totalSolved'] as int? ?? 0,
        totalMoves: json['totalMoves'] as int? ?? 0,
        totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
        hintsUsed: json['hintsUsed'] as int? ?? 0,
        dailyCompleted: json['dailyCompleted'] as int? ?? 0,
      );
}

/// Abstract contract for persistence of progress, level results, snapshots, achievements, and statistics.
abstract class SaveRepository {
  Future<void> init();

  Future<void> saveProgress(PlayerProgress progress);
  Future<PlayerProgress> loadProgress();

  Future<void> saveLevelResult(LevelResult result);
  Future<LevelResult?> loadLevelResult(int levelNumber);
  Future<List<LevelResult>> loadAllLevelResults();

  Future<void> saveSnapshot(GameSnapshot snapshot);
  Future<GameSnapshot?> loadSnapshot();
  Future<void> clearSnapshot();

  Future<void> saveAchievements(List<String> unlockedIds);
  Future<List<String>> loadAchievements();

  Future<void> saveStats(PlayerStats stats);
  Future<PlayerStats> loadStats();
}

/// In-memory implementation of [SaveRepository] for widget tests and guest/web play.
class InMemorySaveRepository implements SaveRepository {
  PlayerProgress _progress = const PlayerProgress();
  final Map<int, LevelResult> _levelResults = {};
  GameSnapshot? _snapshot;
  final Set<String> _achievements = {};
  PlayerStats _stats = const PlayerStats();

  @override
  Future<void> init() async {}

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    _progress = progress;
  }

  @override
  Future<PlayerProgress> loadProgress() async => _progress;

  @override
  Future<void> saveLevelResult(LevelResult result) async {
    _levelResults[result.levelNumber] = result;
  }

  @override
  Future<LevelResult?> loadLevelResult(int levelNumber) async =>
      _levelResults[levelNumber];

  @override
  Future<List<LevelResult>> loadAllLevelResults() async =>
      _levelResults.values.toList()
        ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<GameSnapshot?> loadSnapshot() async => _snapshot;

  @override
  Future<void> clearSnapshot() async {
    _snapshot = null;
  }

  @override
  Future<void> saveAchievements(List<String> unlockedIds) async {
    _achievements.addAll(unlockedIds);
  }

  @override
  Future<List<String>> loadAchievements() async => _achievements.toList();

  @override
  Future<void> saveStats(PlayerStats stats) async {
    _stats = stats;
  }

  @override
  Future<PlayerStats> loadStats() async => _stats;
}
