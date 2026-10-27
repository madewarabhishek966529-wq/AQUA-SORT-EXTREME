# Phase 4 — Progression, Persistence, Settings, Daily Challenge

Prereq: Phase 3 done.

## Build
- `SaveRepository` interface; SQLite implementation (`sqflite_common_ffi` on desktop). Tables: progress, level_results (best moves, best time, stars), stats, achievements, unlocks, in-progress snapshot.
- Continue restores exact in-progress state, history, and timer after restart or suspend.
- Level unlocking, stars, coins, hint currency (hints never required).
- Daily challenge: seed from UTC date, generated deterministically; same date gives same puzzle.
- Challenge modes: limited moves, limited undo, boss levels at milestones.
- `AchievementManager` (event-driven, tested).
- Settings: sound, music, animation intensity, reduced motion, colorblind palette, auto-pour.
- Functional screens: Play, Continue, Level select, Difficulty, Daily, Statistics, Skins, Achievements, Settings.

## Tests
Save/restore round trip, schema migration, daily seed determinism, achievement triggers, unlock rules, continue after simulated kill.

## Done when
Close and reopen preserves progress, in-progress level, and settings. No placeholder menu items.
