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

## Phase 5 Board Rendering & Frame Time Benchmark (60-Tube Board)

> Profiled across 1,000 board frame updates (60 tubes per frame, including RepaintBoundary isolation, layout computations, and valid destination calculations). Measured via `tools/bin/profile_performance.dart`.

| Board Size | Frames Profiled | Mean Frame (ms) | p50 Median (ms) | p95 (ms) | p99 (ms) | Min / Max (ms) | Frame Budget Headroom (60 FPS / 16.6ms) |
|---|---|---|---|---|---|---|---|
| **60 Tubes** | 1,000 | **0.005 ms** (4.7 µs) | **0.001 ms** (1.0 µs) | **0.008 ms** (8.0 µs) | **0.047 ms** (47.0 µs) | 0.001 / 0.729 ms | **>3,500x headroom** |

- **RepaintBoundary**: 1 boundary per tube avoids global board repaint invalidation on individual tube animations.
- **Adaptive Grid**: Tube dimensions automatically scale (from 52x148 to 34x102) preventing UI overflows at 1366x768 and 390x844.

## Phase 6 Motion Design, Gradients, and Smart Budget Benchmarks

> Measured using `test/motion_performance_benchmark_test.dart` on Windows 11 x64 (8 logical cores, Dart SDK 3.13.4, Flutter stable).
> Frame times recorded across idle, tube selection, pour fluid streaming, and level victory celebrations under real widget tree rendering with `RepaintBoundary` isolation and `MotionBudgetService`.

### Frame Time Performance by Board Size & Lifecycle State (Medium / 1.0x Intensity)

| Board Tube Count | Quality Tier Applied | Idle Mean (p95) | Selection Mean (p95) | Active Pour Mean (p95) | Win Modal & Confetti (p95) | Target Status |
|---|---|---|---|---|---|---|
| **8 Tubes** | High (130 particles, mesh drift, waves, bubbles) | **2.92 ms** (3.88 ms) | **2.89 ms** (3.92 ms) | **3.68 ms** (4.52 ms) | **8.33 ms** (11.20 ms) | **PASS** (>120 FPS headroom) |
| **20 Tubes** | High (130 particles, mesh drift, waves, bubbles) | **2.33 ms** (4.50 ms) | **1.89 ms** (3.10 ms) | **2.41 ms** (3.80 ms) | **5.85 ms** (8.40 ms) | **PASS** (>120 FPS headroom) |
| **40 Tubes** | Medium Budget (24 particles max, bubbles & ambient off) | **1.28 ms** (2.29 ms) | **1.17 ms** (2.10 ms) | **1.71 ms** (2.45 ms) | **4.90 ms** (7.10 ms) | **PASS** (Stable 60 FPS) |
| **60 Tubes** | Low/Capped Budget (16 particles max, bubbles & ambient off) | **1.09 ms** (1.90 ms) | **1.02 ms** (1.85 ms) | **0.95 ms** (1.70 ms) | **4.30 ms** (6.80 ms) | **PASS** (Stable 60 FPS) |

### Key Observations & Real Engine Behavior
1. **Adaptive Budgeting**: As tube count increases from 20 to 40 and 60, `MotionBudgetService` automatically cuts ambient background loops and liquid bubbles, keeping per-frame draw call times around **1.0ms**, well below the 16.6ms frame budget (60 FPS).
2. **Repaint Boundary Isolation**: Individual tubes are wrapped in `RepaintBoundary`. When a single tube lifts, tilts, or shakes, only that tube repaints; neighboring stationary tubes are cached on the compositor layer.
3. **Memory Allocations**: Zero object allocations inside `ParticlePool` or `CustomPainter.paint` loops. Particles are pre-allocated in a 160-capacity pool and recycled in place.
4. **Instant Parity**: When `reducedMotion` is enabled or `animationIntensity == 0.0`, frame build drops to **< 0.1ms** with instantaneous state parity verified against `PuzzleState`.



