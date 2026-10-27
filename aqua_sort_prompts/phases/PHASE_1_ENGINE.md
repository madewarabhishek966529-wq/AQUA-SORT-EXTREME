# Phase 1 — Pure-Dart Engine Package

Read `00_MASTER_PROMPT.md` and `docs/ENGINE_SPEC.md` first.

## Goal
Create `packages/aqua_engine` (pure Dart, no Flutter imports) with the rules and a reverse-move level generator.

## Build
- `TubeState`, `PuzzleState` (immutable, capacity configurable, default 4), color ids as small ints.
- `Move` (from, to, count, color) and `MoveValidator` (`isLegal`, `apply`, `legalMoves`) implementing the forward rule exactly as in ENGINE_SPEC.
- `isSolved` per ENGINE_SPEC.
- Compact encoding + `canonicalKey()` (sort tubes so tube order doesn't matter) and JSON serialization with round-trip.
- `PuzzleGenerator` using the exact reverse move defined in ENGINE_SPEC, seeded (`Random(seed)`), returning `GeneratedLevel { initial, solution (reversed scramble), seed, settings }`.
- Reject trivial results (already solved, solution too short, too little fragmentation).
- `LevelValidator.replay(level)` replays the stored solution through `MoveValidator`.

## Tests (must exist and pass)
Valid/invalid pours, capacity, partial group transfer, victory detection, serialization round-trip, canonicalization equivalence, determinism (same seed → identical level), property test: for N random seeds `replay` ends solved, property test: forward(reverse(S)) == original state.

## Done when
- `dart analyze` clean, `dart test` green.
- 1,000 seeded generated levels across 8, 20, 40, 60 tubes all replay to solved.
- Generation time per size recorded in `docs/BENCHMARKS.md` (real numbers).
