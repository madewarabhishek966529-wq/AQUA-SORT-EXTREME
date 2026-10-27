# Review of the original prompt

**Strong:** engine/UI separation, single authoritative state, honest-reporting rules, clear done criteria, staged build order.

**Fixed in this pack**
1. Scope too large for one run: split into 5 phases with checklists.
2. Redundant verification: reverse generation already yields a known solution; the solver is for cross-checks, hints, metrics.
3. Reverse move underspecified: exact definition in `ENGINE_SPEC.md`.
4. Tiers defined only by tube count: metric-based tiers in `DIFFICULTY_METRICS.md`.
5. Hints on huge boards: heuristic/beam search with budget and "Hint unavailable".
6. Platform gaps: `sqflite_common_ffi`, isolates, pure-Dart engine, MSIX named.
7. Assets: procedural or CC0 audio, no stubs.
8. Demo requirement: integration-test fallback if the GUI can't run.
9. Missing choices: Riverpod, folder layout, version pinning declared.
