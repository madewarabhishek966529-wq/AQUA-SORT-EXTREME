import 'dart:math';

import '../levels/generated_level.dart';
import '../levels/level_validator.dart';
import '../model/move.dart';
import '../model/puzzle_state.dart';
import '../model/tube_state.dart';
import '../rules/move_validator.dart';
import 'generation_settings.dart';

/// Represents a candidate reverse move during scramble generation.
class _CandidateReverseMove {
  final int from; // Tube B in S (source of reverse move, destination of forward move)
  final int to;   // Tube A in S (destination of reverse move, source of forward move)
  final int count; // j units transferred
  final int color; // color c
  final PuzzleState nextState; // S'
  final Move forwardMove; // A -> B
  final int deltaFragmentation;

  const _CandidateReverseMove({
    required this.from,
    required this.to,
    required this.count,
    required this.color,
    required this.nextState,
    required this.forwardMove,
    required this.deltaFragmentation,
  });
}

/// Generates valid, solvable Aqua Sort puzzles by performing reversible scrambles
/// from a solved state, following ENGINE_SPEC rules.
class PuzzleGenerator {
  final MoveValidator validator;

  const PuzzleGenerator({this.validator = const StandardMoveValidator()});

  /// Creates an authoritative solved state for the given [settings].
  PuzzleState createSolvedState(GenerationSettings settings) {
    final tubes = <TubeState>[];

    // Colored tubes: 1 per color, filled with `capacity` units of that color.
    for (var c = 1; c <= settings.numColors; c++) {
      final units = List<int>.filled(settings.capacity, c);
      tubes.add(TubeState(units, capacity: settings.capacity));
    }

    // Empty tubes
    for (var e = 0; e < settings.emptyTubes; e++) {
      tubes.add(TubeState.empty(capacity: settings.capacity));
    }

    return PuzzleState(tubes, capacity: settings.capacity);
  }

  /// Generates a [GeneratedLevel] deterministically given a [seed] and [settings].
  /// Retries with derived seeds if the scramble produces a trivial puzzle.
  GeneratedLevel generate(int seed, GenerationSettings settings, {int maxAttempts = 20}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final currentSeed = seed + attempt * 7919;
      final rng = Random(currentSeed);

      final level = _generateSingle(currentSeed, settings, rng);
      if (level != null) {
        return level;
      }
    }

    // Fallback: generate without strict threshold filtering to always guarantee a level
    final fallbackRng = Random(seed);
    final fallback = _generateSingle(seed, settings, fallbackRng, lenient: true);
    if (fallback != null) {
      return fallback;
    }

    throw StateError('Failed to generate puzzle for seed: $seed after $maxAttempts attempts');
  }

  GeneratedLevel? _generateSingle(
    int seed,
    GenerationSettings settings,
    Random rng, {
    bool lenient = false,
  }) {
    var state = createSolvedState(settings);
    final scrambleForwardMoves = <Move>[];
    int? lastFrom;
    int? lastTo;
    int? lastCount;

    for (var step = 0; step < settings.scrambleSteps; step++) {
      final candidates = _findReverseCandidates(state, lastFrom, lastTo, lastCount);
      if (candidates.isEmpty) {
        // No valid candidates without undo; try including all candidates
        final anyCandidates = _findReverseCandidates(state, null, null, null);
        if (anyCandidates.isEmpty) {
          // Cannot scramble further
          break;
        }
        final chosen = _pickWeightedCandidate(anyCandidates, rng);
        state = chosen.nextState;
        scrambleForwardMoves.add(chosen.forwardMove);
        lastFrom = chosen.from;
        lastTo = chosen.to;
        lastCount = chosen.count;
      } else {
        final chosen = _pickWeightedCandidate(candidates, rng);
        state = chosen.nextState;
        scrambleForwardMoves.add(chosen.forwardMove);
        lastFrom = chosen.from;
        lastTo = chosen.to;
        lastCount = chosen.count;
      }
    }

    // The solution is the inverted forward moves in REVERSE order
    final solution = scrambleForwardMoves.reversed.toList();

    // Trivial checks
    if (state.isSolved) return null;
    if (!lenient) {
      if (solution.length < settings.minSolutionLength) return null;
      if (state.fragmentation < settings.minFragmentation) return null;
    }

    final candidateLevel = GeneratedLevel(
      initial: state,
      solution: solution,
      seed: seed,
      settings: settings,
    );

    // Verify through LevelValidator
    final validation = LevelValidator(validator: validator).replay(candidateLevel);
    if (!validation.isValid) {
      return null;
    }

    return candidateLevel;
  }

  /// Finds all candidate reverse moves from [state].
  /// [lastFrom], [lastTo], [lastCount] prevent immediate undo:
  /// if last reverse move was B -> A with count j, next cannot be A -> B with count j.
  List<_CandidateReverseMove> _findReverseCandidates(
    PuzzleState state,
    int? lastFrom,
    int? lastTo,
    int? lastCount,
  ) {
    final candidates = <_CandidateReverseMove>[];
    final tubeCount = state.tubeCount;
    final currentTotalFragmentation = state.totalColorChanges;

    // Fast list of candidate target tubes A (must have free space)
    final availableTargets = <int>[];
    for (var a = 0; a < tubeCount; a++) {
      if (state.tubes[a].freeSpace > 0) {
        availableTargets.add(a);
      }
    }

    for (var b = 0; b < tubeCount; b++) {
      final tubeB = state.tubes[b];
      if (tubeB.isEmpty) continue;

      final color = tubeB.topColor!;
      final topRun = tubeB.topColorCount;

      for (final a in availableTargets) {
        if (a == b) continue;
        final tubeA = state.tubes[a];
        final maxJ = min(topRun, tubeA.freeSpace);

        for (var j = 1; j <= maxJ; j++) {
          // Avoid immediate undo: if last move was B_prev -> A_prev with count j,
          // then moving A_prev -> B_prev with count j reverses it immediately.
          if (lastFrom != null && lastTo != null && lastCount != null) {
            if (b == lastTo && a == lastFrom && j == lastCount) {
              continue;
            }
          }

          // Condition 4: after removing j units from B, B is empty or new top is color
          final remainingB = tubeB.units.length - j;
          if (remainingB > 0 && tubeB.units[remainingB - 1] != color) {
            continue;
          }

          // Condition 5: either A's top in S is not color, or B is full in S
          if (tubeA.topColor == color && !tubeB.isFull) {
            continue;
          }

          // Construct candidate predecessor state S'
          final newB = tubeB.withPouredOut(j);
          final newA = tubeA.withPouredIn(color, j);

          final nextTubes = List.of(state.tubes);
          nextTubes[b] = newB;
          nextTubes[a] = newA;
          final nextState = PuzzleState(nextTubes, capacity: state.capacity);

          // Corresponding forward move from S' is: A -> B, count j, color
          final forwardMove = Move(from: a, to: b, count: j, color: color);

          // Cross check with forward move legality
          if (!validator.isLegal(nextState, forwardMove)) {
            continue;
          }
          final applied = validator.apply(nextState, forwardMove);
          if (applied != state) {
            continue;
          }

          final deltaFrag = nextState.totalColorChanges - currentTotalFragmentation;

          candidates.add(_CandidateReverseMove(
            from: b,
            to: a,
            count: j,
            color: color,
            nextState: nextState,
            forwardMove: forwardMove,
            deltaFragmentation: deltaFrag,
          ));
        }
      }
    }

    return candidates;
  }

  /// Picks a candidate weighted by fragmentation preference.
  _CandidateReverseMove _pickWeightedCandidate(
    List<_CandidateReverseMove> candidates,
    Random rng,
  ) {
    if (candidates.length == 1) return candidates.first;

    // Assign weights:
    // delta > 0: weight 5
    // delta == 0: weight 2
    // delta < 0: weight 1
    var totalWeight = 0;
    final weights = List<int>.filled(candidates.length, 0);

    for (var i = 0; i < candidates.length; i++) {
      final delta = candidates[i].deltaFragmentation;
      final w = delta > 0 ? 5 : (delta == 0 ? 2 : 1);
      weights[i] = w;
      totalWeight += w;
    }

    var roll = rng.nextInt(totalWeight);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        return candidates[i];
      }
    }

    return candidates.last;
  }
}
