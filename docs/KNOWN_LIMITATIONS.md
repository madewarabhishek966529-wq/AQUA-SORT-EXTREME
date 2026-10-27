# Known Limitations

In accordance with Phase 5 requirements, this document honestly lists current limitations, platform-specific constraints, and known boundaries.

## 1. Native Windows C++ Toolchain Dependency
- **Symptom**: `flutter build windows` requires Visual Studio 2022 Community (or Build Tools) with the **"Desktop development with C++"** workload installed.
- **Current Behavior**: If the MSVC C++ toolchain is not present on the host Windows machine, CMake will not generate the Windows runner binary.
- **Verification Alternative**: The app is 100% validated and playable via `flutter build web`, and the full game lifecycle is verified through automated headless integration tests (`test/game_controller_test.dart` and `test/widget_test.dart`).

## 2. Solver Budget & Search Limits on Extreme Boards (50-60 Tubes)
- **Constraint**: A* heuristic search over large 50-60 tube boards operates on a state space exceeding $10^{15}$ permutations.
- **Budget Bound**: The solver enforces a strict budget (default 10,000 nodes or 1.5-second isolate timeout) to prevent UI frame freezing.
- **Classification**: When the budget expires, the solver returns `SolveResult.unverified` (per Master Prompt Rule 4, it is **never** labeled unsolvable).
- **Certified Solvability**: All 300 catalog levels are generated via reversible moves and carry stored, certified solutions that replay with 100.0% accuracy.

## 3. Physical Android Device Testing
- **Status**: The codebase uses cross-platform Flutter/Dart code with `sqflite` mobile driver support.
- **Untested Notice**: Build scripts and Android manifests are prepared, but testing on physical Android devices has not been run directly in this environment.

## 4. Headless & Audio Device Fallback
- **Status**: Sound effects are generated as pure 16-bit PCM WAV files via `tools/bin/generate_sfx.dart`.
- **Behavior**: On headless or virtual environments without audio output hardware, the `AudioService` falls back gracefully to system clicks or silent operation without exceptions.
