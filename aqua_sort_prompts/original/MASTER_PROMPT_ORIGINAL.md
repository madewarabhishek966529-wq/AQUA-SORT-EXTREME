# PROJECT MASTER PROMPT — AQUA SORT: EXTREME (original, condensed faithfully)

## 1. Project Overview
Act as a senior game developer, game architect, puzzle algorithm engineer, UI/UX designer, and QA engineer.
Build a complete, production-quality color-sorting puzzle game called **Aqua Sort: Extreme**. Fully playable, genuinely challenging puzzles, smooth liquid-pouring animations, modern interface, hundreds of progressively difficult levels. Not a UI prototype, static demo, or random unsolvable puzzles.
**Core concept:** Players sort colored liquid layers into separate tubes. A move transfers the top contiguous group of the same color into an empty tube or onto a matching color, subject to capacity and rules.
Differentiator: extreme difficulty, levels with 40, 50, and eventually 60+ bottles.

## 2. Core Gameplay Requirements
- Tube capacity: four units; each unit one color.
- Select source and destination tube.
- Pour only if destination has capacity and is empty or top color matches source top.
- Transfer the maximum contiguous top group that fits.
- Reject invalid moves with subtle feedback.
- Undo, restart, hint, pause, level completion.
- Option: automatic pouring vs tap-to-pour.
- Never change puzzle state incorrectly during animation.
- Victory only when all required colors are sorted.
- Show moves, elapsed time, level number, optional best score.
Single authoritative puzzle state. Animations reflect state transitions, never change liquid data independently.

## 3. Extreme Level Design
Tiers: Beginner 8–12, Intermediate 13–20, Hard 21–30, Expert 31–40, Nightmare 41–50, Impossible 51–60+ tubes (target ranges).
Progression gradually increases colors, bottle count, planning depth, complexity.
Include: 40–60+ tube levels; responsive large boards; multiple empty tubes early, fewer in harder puzzles; multi-stage rearrangements; optional limited-move and limited-undo challenges; gradually unlocked special rules; daily challenges; boss levels; no luck-based mechanics.
Difficulty must come from state-space structure, not just bottle count.

## 4. Puzzle Generation and Verification Engine
Dedicated engine independent of UI.
Required: reverse-state generation; state-space search (A*, IDA*, optimized BFS); state normalization; memoization; shared move validation between game and solver; solution reconstruction; difficulty estimation (solution length, branching factor, search effort, structural complexity); level validation (at least one valid solution before publishing); performance controls (budgets, cancellation, bounded memory); deterministic seeds.
Never claim unsolvable because a search limit was hit; mark unverified.
Hybrid strategy: generate from solved states, apply legal reversible scrambles, reject trivial results, verify, store in local catalog, generate more without blocking UI.
Over-budget puzzles stay unpublished/pending. No exact shortest-path proof required; a valid solution plus difficulty metrics suffices.

## 5. UI/UX Design
Deep navy/charcoal backgrounds, bright distinct liquids, rounded buttons, subtle gradients, glass-like tubes, shadows, completion particles, readable typography, accessible controls.
Main menu: Play, Continue, Level selection, Difficulty selection, Daily challenge, Statistics, Skins/themes, Achievements, Settings.
Gameplay: top bar (Home, level, Undo, Restart, Hint, Settings/Pause); central tube grid; bottom panel (moves, timer, progress, boosters).
40–60+ tubes: adaptive grid, scrollable board, responsive sizing, zoom, persistent controls, clear selection, valid-destination indicators, mouse/touch/keyboard. Playable on desktop and mobile.

## 6. Liquid-Pouring Animations
Selection, lift and tilt, stream, transfer, return, invalid feedback, undo/restart, completion, reward collection. Smooth and cancellable. Engine blocks conflicting moves during a pour. Rendered liquid always matches state. Reusable animation system.

## 7. Hint System
Connected to solver. Legal, progress-making moves; avoid repeating unproductive suggestions; optional stronger multi-step hints; based on current state. If no solution within budget, honest "Hint unavailable". Optional rewarded hints/currency, never required for ordinary levels.

## 8. Progression and Rewards
Hundreds of levels, unlocking, persistent records, coins/stars, daily challenges, achievements, best moves/time, theme and skin unlocks, optional leaderboards. Local save; no account or internet for core play.

## 9. Audio and Accessibility
Configurable SFX: select, pour, invalid, undo, victory, reward. Sound/music toggles, animation intensity, colorblind palettes, contrast, non-color-only states, reduced motion. Usable without audio.

## 10. Technical Architecture
Separate: game state/rules, generation, solving, validation, animation/rendering, UI, save/load, audio, achievements, settings, tests.
Suggested modules: PuzzleState, TubeState, MoveValidator, PuzzleSolver, PuzzleGenerator, LevelValidator, DifficultyEvaluator, GameController, PourAnimationController, SaveManager, LevelRepository, AchievementManager, SettingsManager.
Immutable or controlled state transitions. Document public interfaces and solver algorithms.

## 11. Performance Requirements
Responsive UI during generation/solving; searches off main thread; cancellation and budgets; efficient encoding/hashing; canonicalization; caching; minimal redraws; safe suspend/resume; test 40, 50, 60+ tube boards. Do not promise instant 60-tube solves; benchmark and adjust.

## 12. Testing and QA
Unit tests: pours, capacity, color matching, group transfer, victory, undo/restart, serialization, normalization, solver correctness, solvability, difficulty classification, save/restore, animation/state sync. Integration tests: full playthroughs.
Per certified level: validate initial state, obtain solution, replay through real validator, confirm solved, save with seed, confirm metrics meet tier. Performance tests on largest boards; report real benchmarks.

## 13. Development and Delivery
Full source, assets, gameplay, engine, catalog, save system, tests, build config, README, one-command dev launch, production build, desktop packaging/installer instructions, architecture doc, troubleshooting guide. No placeholders, fake stats, mock solutions, or dead menus. State exactly what is incomplete.

## 14. Definition of Done
Launches; real puzzles solvable; undo/restart/hints/progression work; levels validated; extreme boards usable; progress persists; animations never corrupt state; tests pass; build instructions work on clean setup; performance limits documented honestly.

## 15. Technology Declaration
Flutter + Dart. Animation: AnimationController, CustomPainter, reusable widgets. Engine: pure Dart. Persistence: SQLite (sqflite where supported, or desktop-compatible SQLite). Local settings store. Tests: Dart unit, Flutter widget, integration. Initial platform: Windows 10/11; future Android. No backend for core play. Verify Windows support for every dependency.

**Final instruction:** Inspect environment, create project, build a playable vertical slice (rules, rendering, pouring, undo, restart, completion), then solver and verified generator, then extreme-level UI, progression, persistence, polish, testing. Run and demonstrate a completed puzzle before declaring finished.
