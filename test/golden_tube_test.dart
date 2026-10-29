import 'package:aqua_engine/aqua_engine.dart';
import 'package:aqua_sort_extreme/theme/aqua_palette.dart';
import 'package:aqua_sort_extreme/theme/tube_skins.dart';
import 'package:aqua_sort_extreme/ui/painters/tube_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Visual Representation Tests for Key Tubes across Themes', () {
    final emptyTube = TubeState.empty();
    final mixedTube = TubeState([1, 2, 3], capacity: 4);
    final fullSingleColorTube = TubeState([4, 4, 4, 4], capacity: 4);

    Finder findTubeCustomPaint() {
      return find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TubePainter);
    }

    Widget buildTubeWidget({
      required TubeState tube,
      required ThemePalette theme,
      required TubeSkin skin,
      bool isSelected = false,
      bool showColorblindCues = false,
      bool colorblindPalette = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: theme.backgroundBase,
          body: Center(
            child: SizedBox(
              width: 52,
              height: 148,
              child: CustomPaint(
                painter: TubePainter(
                  tube: tube,
                  isSelected: isSelected,
                  theme: theme,
                  skin: skin,
                  showColorblindCues: showColorblindCues,
                  colorblindPalette: colorblindPalette,
                  glowColor: isSelected ? theme.primaryAccent : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Ocean Theme: empty, mixed, full, and selected tubes render without error',
        (WidgetTester tester) async {
      final theme = AquaPalette.ocean;
      final skin = TubeSkinRegistry.classicGlass;

      // 1. Empty Tube
      await tester.pumpWidget(buildTubeWidget(tube: emptyTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Mixed Tube
      await tester.pumpWidget(buildTubeWidget(tube: mixedTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Full Single-Color Tube
      await tester.pumpWidget(buildTubeWidget(tube: fullSingleColorTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Selected Tube
      await tester.pumpWidget(buildTubeWidget(
        tube: mixedTube,
        theme: theme,
        skin: skin,
        isSelected: true,
      ));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Neon Night Theme: empty, mixed, full, and selected tubes render without error',
        (WidgetTester tester) async {
      final theme = AquaPalette.neonNight;
      final skin = TubeSkinRegistry.neonCyber;

      // 1. Empty Tube
      await tester.pumpWidget(buildTubeWidget(tube: emptyTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Mixed Tube
      await tester.pumpWidget(buildTubeWidget(tube: mixedTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Full Single-Color Tube
      await tester.pumpWidget(buildTubeWidget(tube: fullSingleColorTube, theme: theme, skin: skin));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Selected Tube
      await tester.pumpWidget(buildTubeWidget(
        tube: fullSingleColorTube,
        theme: theme,
        skin: skin,
        isSelected: true,
      ));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Colorblind Mode: renders accessible pattern symbols on all liquid units',
        (WidgetTester tester) async {
      final theme = AquaPalette.ocean;
      final skin = TubeSkinRegistry.classicGlass;

      await tester.pumpWidget(buildTubeWidget(
        tube: mixedTube,
        theme: theme,
        skin: skin,
        showColorblindCues: true,
        colorblindPalette: true,
      ));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final customPaint = tester.widget<CustomPaint>(findTubeCustomPaint());
      final painter = customPaint.painter as TubePainter;
      expect(painter.showColorblindCues, isTrue);
      expect(painter.colorblindPalette, isTrue);
      expect(painter.tube.units.length, equals(3));
    });

    testWidgets('Steampunk skin with metallic base cap renders properly',
        (WidgetTester tester) async {
      final theme = AquaPalette.sunsetLava;
      final skin = TubeSkinRegistry.steampunkCopper;

      await tester.pumpWidget(buildTubeWidget(
        tube: mixedTube,
        theme: theme,
        skin: skin,
      ));
      expect(findTubeCustomPaint(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final customPaint = tester.widget<CustomPaint>(findTubeCustomPaint());
      final painter = customPaint.painter as TubePainter;
      expect(painter.skin.hasBaseCap, isTrue);
      expect(painter.skin.baseCapColor, isNotNull);
    });
  });
}
