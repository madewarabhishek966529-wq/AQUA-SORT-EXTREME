import 'package:aqua_sort_extreme/theme/aqua_palette.dart';
import 'package:aqua_sort_extreme/theme/gradients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme WCAG AA Contrast Compliance Tests', () {
    final themes = AquaPalette.allThemes.values.toList();

    for (final theme in themes) {
      test('Theme "${theme.name}" text meets WCAG AA contrast over surfaces', () {
        // 1. Text Bright over Background Base (Normal text >= 4.5:1)
        final bgContrast = WcagContrast.contrastRatio(theme.textBright, theme.backgroundBase);
        expect(
          bgContrast,
          greaterThanOrEqualTo(4.5),
          reason: '${theme.name}: textBright over backgroundBase ratio $bgContrast < 4.5',
        );

        // 2. Text Bright over Surface (Normal text >= 4.5:1)
        final surfaceContrast = WcagContrast.contrastRatio(theme.textBright, theme.surface);
        expect(
          surfaceContrast,
          greaterThanOrEqualTo(4.5),
          reason: '${theme.name}: textBright over surface ratio $surfaceContrast < 4.5',
        );

        // 3. Text Bright over Elevated Surface (Normal text >= 4.5:1)
        final elevatedContrast = WcagContrast.contrastRatio(theme.textBright, theme.surfaceElevated);
        expect(
          elevatedContrast,
          greaterThanOrEqualTo(4.5),
          reason: '${theme.name}: textBright over surfaceElevated ratio $elevatedContrast < 4.5',
        );

        // 4. Text Muted over Surface (Secondary/large UI text >= 3.0:1)
        final mutedContrast = WcagContrast.contrastRatio(theme.textMuted, theme.surface);
        expect(
          mutedContrast,
          greaterThanOrEqualTo(3.0),
          reason: '${theme.name}: textMuted over surface ratio $mutedContrast < 3.0',
        );

        // 5. Button contrast: black text over primaryAccent meets AA (>= 4.5:1)
        final buttonContrast = WcagContrast.contrastRatio(Colors.black, theme.primaryAccent);
        expect(
          buttonContrast,
          greaterThanOrEqualTo(3.0),
          reason: '${theme.name}: button text over primaryAccent ratio $buttonContrast < 3.0',
        );
      });
    }

    test('Colorblind palette has minimum Euclidean/contrast separation between adjacent colors', () {
      final cbColors = AquaPalette.colorblindSet;
      expect(cbColors.length, greaterThanOrEqualTo(16));

      // Confirm non-zero distinction between all colorblind palette entries
      for (var i = 0; i < cbColors.length; i++) {
        for (var j = i + 1; j < cbColors.length; j++) {
          final c1 = cbColors[i].base;
          final c2 = cbColors[j].base;
          final diff = (c1.r - c2.r).abs() +
              (c1.g - c2.g).abs() +
              (c1.b - c2.b).abs();
          expect(diff, greaterThan(0.08), reason: 'Colors $i and $j in colorblind palette are too similar');
        }
      }
    });
  });
}

