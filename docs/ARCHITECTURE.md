# Architecture

```
app (Flutter)
  ui/            screens, widgets, painters
  controllers/   GameController, PourAnimationController (Riverpod)
  services/      SaveRepository impl, AudioService, SettingsService
        |
        v
packages/aqua_engine (pure Dart)
  model/         TubeState, PuzzleState, Move
  rules/         MoveValidator, solved check, canonicalization
  generation/    PuzzleGenerator, GenerationSettings
  solving/       PuzzleSolver, SolveBudget, CancelToken, hint planner
  levels/        GeneratedLevel, LevelValidator, DifficultyEvaluator
tools/           catalog builder CLI, benchmark runner
```

## Rules
- Engine has no Flutter, no `dart:ui`, no I/O (I/O lives in `tools/`).
- GameController is the only writer of the live `PuzzleState`. UI sends intents (`selectTube`, `undo`, `restart`, `hint`).
- Move flow: intent -> validator -> commit new state and push history -> emit `PourEvent(from, to, count, color)` -> animation renders the event -> input unlocked on completion. Skipping or cancelling an animation never changes state.
- Solver and generator run through an isolate wrapper with cancellation.
- Persistence behind `SaveRepository`; swap SQLite driver per platform.

## Key interfaces
```dart
abstract class MoveValidator {
  bool isLegal(PuzzleState s, Move m);
  PuzzleState apply(PuzzleState s, Move m);
  List<Move> legalMoves(PuzzleState s);
}
abstract class PuzzleSolver {
  Future<SolveResult> solve(PuzzleState s, SolveBudget b, CancelToken t);
}
abstract class SaveRepository {
  Future<void> saveResult(LevelResult r);
  Future<GameSnapshot?> loadSnapshot();
}
```
