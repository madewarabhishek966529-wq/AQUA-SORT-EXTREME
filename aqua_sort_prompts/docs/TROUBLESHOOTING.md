# Troubleshooting

| Problem | Fix |
|---|---|
| `flutter doctor` shows Visual Studio missing | Install Visual Studio 2022 with the "Desktop development with C++" workload |
| `sqflite` fails on Windows | Use `sqflite_common_ffi`; call `sqfliteFfiInit()` and set `databaseFactory = databaseFactoryFfi` in `main()` |
| `sqlite3.dll` not found | Add `sqlite3_flutter_libs` or bundle the DLL next to the exe |
| UI freezes during generate/solve | Run the solver in an `Isolate`; pass budget and cancel token |
| Liquid wrong after undo | Render only from `PuzzleState`, never from animation-local data |
| Level reported unsolvable | It is `Unverified` unless the search was exhaustive; raise budget or use the stored solution |
| Large board unusable | Check zoom, scroll, minimum tube size; use RepaintBoundary per tube |
| MSIX build fails | Check `msix_config` in `pubspec.yaml`: publisher, identity, certificate |
| Audio missing | Run the SFX generator tool or confirm CC0 files exist in `assets/audio` and are declared in `pubspec.yaml` |
