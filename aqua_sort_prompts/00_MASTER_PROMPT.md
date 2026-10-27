# AQUA SORT: EXTREME — Revised Master Prompt

Use this file as shared context. Run the phase prompts in `phases/` one at a time, in order. Do not start a phase until the previous phase's "Done when" checklist passes.

## Role
Senior Flutter/Dart game engineer, puzzle-algorithm engineer, and QA engineer.

## Product
Aqua Sort: Extreme — a liquid color-sorting puzzle game. Tubes hold 4 units. Boards range from 8 to 60+ tubes. Difficulty comes from state-space structure, not bottle count alone. Fully offline.

## Fixed technical decisions (do not change)
- Flutter stable (pin exact version in `README.md` and `.fvmrc` or `pubspec` environment), Dart 3.x, null safety.
- State management: Riverpod.
- Monorepo layout:
  ```
  aqua_sort/
    packages/aqua_engine/   # pure Dart, NO flutter imports
    app/                    # Flutter app (Windows first, Android later)
    tools/                  # benchmark + level-catalog CLI (pure Dart)
    docs/
  ```
- Persistence: `sqflite_common_ffi` on Windows/desktop, `sqflite` on Android, behind a `SaveRepository` interface. Settings via `shared_preferences`.
- Solver runs in a Dart `Isolate`; UI never blocks.
- Audio: generate SFX procedurally (WAV synthesized by a Dart tool script) or use CC0 sounds with license noted. No missing-asset stubs.
- Windows packaging: MSIX (`msix` package) primary, Inno Setup optional.
- Every dependency: confirm Windows support on pub.dev before adding; record version.

## Non-negotiable rules
1. One authoritative `PuzzleState`. Animations render transitions; they never mutate liquid data.
2. The same `MoveValidator` is used by game, generator, solver, and tests.
3. Hitting a search limit means "unverified", never "unsolvable".
4. Reverse-generated levels already carry a known solution (the reversed scramble). Solver verification is for independent cross-check, hints, and difficulty metrics.
5. No fake stats, placeholder buttons, mock solutions, or invented benchmarks. Report real numbers. State what is incomplete.
6. If the agent cannot run the Windows app, it must prove playability with an automated integration test that plays a level through `GameController`, and say it could not run the GUI.

## Process per phase
Inspect environment → implement → run `dart analyze` and tests → fix → report results against the phase checklist.

## Phase order
1. `phases/PHASE_1_ENGINE.md`
2. `phases/PHASE_2_PLAYABLE_UI.md`
3. `phases/PHASE_3_SOLVER_CATALOG.md`
4. `phases/PHASE_4_PROGRESSION_PERSISTENCE.md`
5. `phases/PHASE_5_POLISH_PACKAGING.md`

Reference docs: `docs/ENGINE_SPEC.md`, `docs/DIFFICULTY_METRICS.md`, `docs/ARCHITECTURE.md`, `docs/TESTING_PLAN.md`, `docs/TROUBLESHOOTING.md`, `docs/PROMPT_REVIEW.md`.
