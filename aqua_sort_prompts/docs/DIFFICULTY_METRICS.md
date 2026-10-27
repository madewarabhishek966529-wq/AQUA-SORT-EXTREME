# Difficulty Metrics

Tube count alone does not define difficulty. A tier is a bucket derived from metrics; tube ranges are starting targets.

## Metrics
| Metric | Meaning |
|---|---|
| known_solution_length | Length of the reverse-scramble solution (upper bound on optimal) |
| solver_solution_length | Length of the solver's path, if found |
| empty_ratio | empty tubes / total tubes (lower = harder) |
| fragmentation | average color changes per tube (higher = harder) |
| buried_depth | average depth of the last-needed unit of each color |
| initial_branching | legal moves in the start state |
| avg_branching | mean legal moves along the solution path |
| dead_end_ratio | in a bounded probe, fraction of branches with no progress within K moves |
| search_effort | nodes expanded under a fixed solver budget |

## Starting tier mapping (calibrate with benchmarks)
| Tier | Tubes | Empty tubes | Min solution length | Notes |
|---|---|---|---|---|
| Beginner | 8-12 | 2-3 | ~10 | low fragmentation |
| Intermediate | 13-20 | 2 | ~25 | |
| Hard | 21-30 | 2 | ~45 | |
| Expert | 31-40 | 1-2 | ~70 | |
| Nightmare | 41-50 | 1-2 | ~100 | high dead_end_ratio |
| Impossible | 51-60+ | 1-2 | ~140 | high dead_end_ratio, boss rules |

A level gets a tier only when its size fits the range and at least two of (min solution length, fragmentation, dead_end_ratio) meet that tier's thresholds. Otherwise reclassify lower or reject. Record final calibrated numbers in `BENCHMARKS.md`.
