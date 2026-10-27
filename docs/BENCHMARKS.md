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
| 8 | 250 | 250 / 250 (100%) | 0.84 | 0.47 | 1.46 | 9.70 | 17.6 | 1.59 |
| 20 | 250 | 250 / 250 (100%) | 3.51 | 3.39 | 4.68 | 5.26 | 39.9 | 1.58 |
| 40 | 250 | 250 / 250 (100%) | 16.86 | 16.45 | 20.28 | 22.20 | 73.0 | 1.47 |
| 60 | 250 | 250 / 250 (100%) | 43.04 | 42.16 | 54.34 | 57.57 | 99.3 | 1.39 |

### Verification & Replay
- **Total Levels Tested**: 1,000
- **Replay Success Rate**: 1,000 / 1,000 (100.0%)
- **Total Suite Time**: 16.11 seconds
- **Rule Adherence**: 100% of reverse moves strictly inverted into legal forward moves verified by `MoveValidator.apply`.

