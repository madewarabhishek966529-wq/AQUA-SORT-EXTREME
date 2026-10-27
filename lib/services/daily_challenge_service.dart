import 'package:aqua_engine/aqua_engine.dart';

/// Service providing deterministic daily challenge levels based on UTC date.
class DailyChallengeService {
  final PuzzleGenerator generator;

  const DailyChallengeService({this.generator = const PuzzleGenerator()});

  /// Derives an immutable integer seed from a UTC date: YYYYMMDD.
  static int getDailySeed([DateTime? date]) {
    final d = (date ?? DateTime.now().toUtc());
    return d.year * 10000 + d.month * 100 + d.day;
  }

  /// Returns the day of the week (1 = Monday, 7 = Sunday).
  static int getWeekday([DateTime? date]) {
    return (date ?? DateTime.now().toUtc()).weekday;
  }

  /// Generates the daily puzzle deterministically for [date].
  GeneratedLevel getDailyLevel([DateTime? date]) {
    final d = (date ?? DateTime.now().toUtc());
    final seed = getDailySeed(d);
    final weekday = d.weekday;

    // Difficulty scales throughout the week: Sunday is a Boss Challenge!
    final tubeCount = switch (weekday) {
      DateTime.monday => 12,
      DateTime.tuesday => 14,
      DateTime.wednesday => 16,
      DateTime.thursday => 18,
      DateTime.friday => 20,
      DateTime.saturday => 24,
      DateTime.sunday => 28, // Boss Challenge Sunday!
      _ => 16,
    };

    final settings = GenerationSettings.forTubeCount(tubeCount);
    return generator.generate(seed, settings);
  }

  /// Returns challenge constraints (e.g. max moves and max undos).
  ChallengeConstraints getConstraints(GeneratedLevel level) {
    // 35% margin over known solution length
    final maxMoves = (level.solution.length * 1.35).ceil();
    return ChallengeConstraints(
      maxMoves: maxMoves,
      maxUndos: 3,
      isBossLevel: level.initial.tubeCount >= 24,
    );
  }
}

class ChallengeConstraints {
  final int maxMoves;
  final int maxUndos;
  final bool isBossLevel;

  const ChallengeConstraints({
    required this.maxMoves,
    required this.maxUndos,
    required this.isBossLevel,
  });
}
