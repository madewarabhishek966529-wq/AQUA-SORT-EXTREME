import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/controllers/game_controller.dart';
import 'package:aqua_sort_extreme/services/achievement_manager.dart';
import 'package:aqua_sort_extreme/services/settings_service.dart';
import 'package:aqua_sort_extreme/services/save_repository.dart';
import 'package:aqua_sort_extreme/ui/screens/game_screen.dart';
import 'package:aqua_sort_extreme/ui/screens/main_menu_screen.dart';
import 'package:aqua_sort_extreme/ui/theme/game_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('GameScreen renders top bar, tubes, and bottom bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GameScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify TopBar elements
    expect(find.textContaining('LEVEL 1'), findsOneWidget);
    expect(find.byKey(const Key('restart_button')), findsOneWidget);
    expect(find.byKey(const Key('undo_button')), findsOneWidget);
    expect(find.byKey(const Key('hint_button')), findsOneWidget);

    // Verify BottomBar elements
    expect(find.byKey(const Key('moves_counter')), findsOneWidget);
    expect(find.byKey(const Key('timer_display')), findsOneWidget);
    expect(find.byKey(const Key('progress_display')), findsOneWidget);

    // Verify tubes exist
    expect(find.byKey(const Key('tube_0')), findsOneWidget);
    expect(find.byKey(const Key('tube_1')), findsOneWidget);
  });

  testWidgets('Tapping tube selects it and second tap deselects',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    late GameController controller;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameControllerProvider.overrideWith((ref) {
            const generator = PuzzleGenerator();
            final settings = GenerationSettings.forTubeCount(8);
            final level = generator.generate(555, settings);
            controller = GameController(initialLevel: level, levelNumber: 1);
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nonEmptyIndex =
        controller.state.puzzleState.tubes.indexWhere((t) => t.isNotEmpty);
    expect(nonEmptyIndex, greaterThanOrEqualTo(0));

    // Tap tube to select
    await tester.tap(find.byKey(Key('tube_$nonEmptyIndex')));
    await tester.pump();
    expect(controller.state.selectedTubeIndex, equals(nonEmptyIndex));

    // Tap same tube to deselect
    await tester.tap(find.byKey(Key('tube_$nonEmptyIndex')));
    await tester.pump();
    expect(controller.state.selectedTubeIndex, isNull);
  });

  testWidgets('Valid pour updates moves and undo button reverses it',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    late GameController controller;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameControllerProvider.overrideWith((ref) {
            const generator = PuzzleGenerator();
            final settings = GenerationSettings.forTubeCount(8);
            final level = generator.generate(888, settings);
            controller = GameController(initialLevel: level, levelNumber: 1);
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const validator = StandardMoveValidator();
    final legalMoves = validator.legalMoves(controller.state.puzzleState);
    expect(legalMoves, isNotEmpty);
    final move = legalMoves.first;

    // Tap from tube
    await tester.tap(find.byKey(Key('tube_${move.from}')));
    await tester.pump();

    // Tap to tube
    await tester.tap(find.byKey(Key('tube_${move.to}')));
    await tester.pump();

    expect(controller.state.moves, equals(1));

    // Finish pour animation
    await tester.pump(const Duration(milliseconds: 500));

    // Tap undo button
    await tester.tap(find.byKey(const Key('undo_button')));
    await tester.pumpAndSettle();

    expect(controller.state.moves, equals(1));
    expect(controller.state.history, isEmpty);
  });

  testWidgets('MainMenuScreen renders all hubs and navigation options',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = InMemorySaveRepository();
    await repository.init();
    final settingsService = SettingsService();
    final achievementManager = AchievementManager(repository: repository);
    await achievementManager.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: GameTheme.darkTheme,
          home: MainMenuScreen(
            repository: repository,
            settingsService: settingsService,
            achievementManager: achievementManager,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify MainMenu components
    expect(find.text('AQUA SORT'), findsOneWidget);
    expect(find.text('EXTREME'), findsOneWidget);
    expect(find.textContaining('PLAY'), findsOneWidget);
    expect(find.text('SELECT LEVEL'), findsOneWidget);
    expect(find.text('DIFFICULTY TIERS'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.text('STATS'), findsOneWidget);
    expect(find.text('SKINS'), findsOneWidget);
    expect(find.text('TROPHIES'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
