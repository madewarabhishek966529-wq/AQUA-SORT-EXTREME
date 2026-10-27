# Phase 2 — Playable Flutter UI

Prereq: Phase 1 done.

## Goal
A playable Windows app using `aqua_engine`.

## Build
- Riverpod `GameController` wrapping `PuzzleState`, undo stack, restart, move counter, timer, win detection. Input is locked while a pour animation is active; state is committed first, animation renders the transition.
- Tube rendering with `CustomPainter` (glass outline, highlight, liquid layers).
- Reusable `PourAnimationController`: select-lift, tilt, stream, transfer, return, invalid shake. One controller for all tubes; cancellable; skippable by tap.
- Tap-to-pour and auto-pour option.
- Top bar (home, level, undo, restart, hint disabled until Phase 3), bottom bar (moves, timer).
- Use generated levels from the engine, 8 to 20 tubes.
- Win screen with simple particle effect.

## Tests
Widget: select/deselect, valid pour updates state, invalid pour leaves state unchanged, undo restores exact prior state, rendered liquid equals state after animation, rapid double-tap during pour ignored. Integration: play one generated level to completion by replaying its stored solution through `GameController`.

## Done when
- App launches on Windows (or the agent states it could not run the GUI and the integration test passes).
- Full level completed via test and, if possible, manually.
- Undo/restart never desync liquid from state.
