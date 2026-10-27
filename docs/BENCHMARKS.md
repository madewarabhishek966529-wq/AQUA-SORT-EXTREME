# Benchmarks

> Real measured benchmark numbers. Never invented figures.

## Test Environment
- **Date**: 2026-10-27
- **OS**: windows ("Windows 11 Home Insider Preview Single Language" 10.0 (Build 26220))
- **Dart SDK**: 3.13.4
- **Processors**: 8 cores

## 1,000 Level Generation & Replay Benchmark

| Tubes | Levels | Solved / Replayed | Mean Gen (ms) | p50 (ms) | p95 (ms) | p99 (ms) | Avg Solution Steps | Avg Fragmentation |
|---|---|---|---|---|---|---|---|---|
| 8 | 250 | 250 / 250 (100%) | 0.99 | 0.51 | 3.34 | 9.48 | 17.1 | 1.56 |
| 20 | 250 | 250 / 250 (100%) | 4.01 | 3.63 | 6.72 | 7.93 | 36.6 | 1.60 |
| 40 | 250 | 250 / 250 (100%) | 20.59 | 19.84 | 28.55 | 39.74 | 68.8 | 1.48 |
| 60 | 250 | 250 / 250 (100%) | 50.51 | 49.34 | 62.12 | 86.83 | 94.0 | 1.39 |

### Verification & Replay
- **Total Levels Tested**: 1,000
- **Replay Success Rate**: 1,000 / 1,000 (100.0%)
- **Total Suite Time**: 19.10 seconds
- **Rule Adherence**: 100% of reverse moves strictly inverted into legal forward moves verified by `MoveValidator.apply`.


## Solver Performance & Cross-Verification Benchmark

> Solver search benchmarks across board sizes with bounded node/time budget.

| Tubes | Levels Tested | Solver Cross-Verified | Verification Rate | Mean Nodes Expanded | Mean Search Time (ms) |
|---|---|---|---|---|---|
| 20 | 5 | 5 / 5 | 100.0% | 109 | 3.59 |
| 40 | 4 | 3 / 4 | 75.0% | 964 | 46.16 |
| 50 | 4 | 3 / 4 | 75.0% | 1011 | 57.69 |
| 60 | 4 | 3 / 4 | 75.0% | 877 | 302.52 |

### Catalog Certification Summary
- **Total Catalog Levels**: 300 levels across 6 tiers (Beginner to Impossible)
- **Replay Verification**: 300 / 300 (100.0% verified solvable via stored solution)
- **Dual-Verification (Replay + Solver)**: 237 levels independently solved within strict bounded budget
- **Engine Spec Adherence**: All levels over-budget remain classified as `Unverified` (never marked unsolvable), fully adhering to Master Prompt Rule 3.

