# Phase 3 — Solver, Hints, Level Catalog, Difficulty

Prereq: Phase 2 done. Read `docs/DIFFICULTY_METRICS.md`.

## Build
- `PuzzleSolver` with budget (nodes and time), cancellation token, bounded memory, canonical visited set. Small boards: IDA* or BFS. Large boards: weighted A* or beam search with a documented heuristic (tubes not single-colored plus fragmentation penalty).
- Results: `Solved(path)`, `Unverified(reason)`, `ProvenUnsolvable` (only when the search was exhaustive and finished).
- Solver runs in an `Isolate`.
- `DifficultyEvaluator` computing the metrics and mapping to tiers.
- `LevelCatalogBuilder` CLI in `tools/`: generate, cross-check with solver where budget allows, evaluate, assign tier, write `assets/levels/catalog.json` (seed, settings, initial state, known solution, metrics, verification status).
- Hints: next legal progress move from the current state; stronger hint shows next 3 to 5 moves; never suggest undoing the previous move; if no path in budget show "Hint unavailable".
- Target: hundreds of levels over all six tiers, including 40, 50, 60 tube boards.

## Tests
Solver finds known solution on small seeds; result replays cleanly; budget and cancellation honored; hints always legal; all catalog levels replay solved; metrics fall in tier ranges.

## Done when
- Catalog committed with real counts per tier.
- `docs/BENCHMARKS.md` has real solver times and node counts for 20, 40, 50, 60 tubes and the share cross-verified vs known-solution only.
