import 'dart:convert';
import 'dart:io' show Platform;
import 'package:aqua_engine/aqua_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'save_repository.dart';

/// SQLite implementation of [SaveRepository].
/// Works across Windows/Desktop via `sqflite_common_ffi` and Android/iOS via `sqflite`.
class SqliteSaveRepository implements SaveRepository {
  Database? _db;
  final String? customPath;

  SqliteSaveRepository({this.customPath, Database? db}) {
    _db = db;
  }

  Database get db {
    if (_db == null) {
      throw StateError('SqliteSaveRepository is not initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  Future<void> init() async {
    if (_db != null) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = customPath ?? join(await getDatabasesPath(), 'aqua_sort.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // 1. Progress table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress (
        id INTEGER PRIMARY KEY,
        highest_unlocked INTEGER NOT NULL,
        coins INTEGER NOT NULL,
        stars INTEGER NOT NULL
      )
    ''');

    // 2. Level results table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS level_results (
        level_number INTEGER PRIMARY KEY,
        best_moves INTEGER NOT NULL,
        best_time INTEGER NOT NULL,
        stars INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    // 3. Game in-progress snapshot
    await db.execute('''
      CREATE TABLE IF NOT EXISTS snapshots (
        id INTEGER PRIMARY KEY,
        level_number INTEGER NOT NULL,
        current_state_json TEXT NOT NULL,
        history_json TEXT NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        moves INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // 4. Achievements
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');

    // 5. Lifetime player stats
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_stats (
        id INTEGER PRIMARY KEY,
        total_solved INTEGER NOT NULL,
        total_moves INTEGER NOT NULL,
        total_play_time INTEGER NOT NULL,
        hints_used INTEGER NOT NULL,
        daily_completed INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    await db.insert(
      'progress',
      {
        'id': 1,
        'highest_unlocked': progress.highestUnlockedLevel,
        'coins': progress.coins,
        'stars': progress.stars,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<PlayerProgress> loadProgress() async {
    final rows = await db.query('progress', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      return const PlayerProgress();
    }
    final r = rows.first;
    return PlayerProgress(
      highestUnlockedLevel: r['highest_unlocked'] as int,
      coins: r['coins'] as int,
      stars: r['stars'] as int,
    );
  }

  @override
  Future<void> saveLevelResult(LevelResult result) async {
    await db.insert(
      'level_results',
      {
        'level_number': result.levelNumber,
        'best_moves': result.bestMoves,
        'best_time': result.bestTimeSeconds,
        'stars': result.stars,
        'completed_at': result.completedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<LevelResult?> loadLevelResult(int levelNumber) async {
    final rows = await db.query(
      'level_results',
      where: 'level_number = ?',
      whereArgs: [levelNumber],
    );
    if (rows.isEmpty) return null;
    return LevelResult.fromJson(rows.first);
  }

  @override
  Future<List<LevelResult>> loadAllLevelResults() async {
    final rows = await db.query('level_results', orderBy: 'level_number ASC');
    return rows.map((r) => LevelResult.fromJson(r)).toList();
  }

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    await db.insert(
      'snapshots',
      {
        'id': 1,
        'level_number': snapshot.levelNumber,
        'current_state_json': jsonEncode(snapshot.currentState.toJson()),
        'history_json': jsonEncode(snapshot.history.map((h) => h.toJson()).toList()),
        'elapsed_seconds': snapshot.elapsedSeconds,
        'moves': snapshot.moves,
        'timestamp': snapshot.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<GameSnapshot?> loadSnapshot() async {
    final rows = await db.query('snapshots', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    final r = rows.first;

    final stateJson = jsonDecode(r['current_state_json'] as String) as Map<String, dynamic>;
    final historyList = jsonDecode(r['history_json'] as String) as List<dynamic>;

    return GameSnapshot(
      levelNumber: r['level_number'] as int,
      currentState: PuzzleState.fromJson(stateJson),
      history: historyList.map((h) => PuzzleState.fromJson(h as Map<String, dynamic>)).toList(),
      elapsedSeconds: r['elapsed_seconds'] as int,
      moves: r['moves'] as int,
      timestamp: DateTime.parse(r['timestamp'] as String),
    );
  }

  @override
  Future<void> clearSnapshot() async {
    await db.delete('snapshots', where: 'id = ?', whereArgs: [1]);
  }

  @override
  Future<void> saveAchievements(List<String> unlockedIds) async {
    final batch = db.batch();
    for (final id in unlockedIds) {
      batch.insert(
        'achievements',
        {'id': id, 'unlocked_at': DateTime.now().toUtc().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<String>> loadAchievements() async {
    final rows = await db.query('achievements');
    return rows.map((r) => r['id'] as String).toList();
  }

  @override
  Future<void> saveStats(PlayerStats stats) async {
    await db.insert(
      'player_stats',
      {
        'id': 1,
        'total_solved': stats.totalSolved,
        'total_moves': stats.totalMoves,
        'total_play_time': stats.totalPlayTimeSeconds,
        'hints_used': stats.hintsUsed,
        'daily_completed': stats.dailyCompleted,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<PlayerStats> loadStats() async {
    final rows = await db.query('player_stats', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return const PlayerStats();
    final r = rows.first;
    return PlayerStats(
      totalSolved: r['total_solved'] as int,
      totalMoves: r['total_moves'] as int,
      totalPlayTimeSeconds: r['total_play_time'] as int,
      hintsUsed: r['hints_used'] as int,
      dailyCompleted: r['daily_completed'] as int,
    );
  }
}
