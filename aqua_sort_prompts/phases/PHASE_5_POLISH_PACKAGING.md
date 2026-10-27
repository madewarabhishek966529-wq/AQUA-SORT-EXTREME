# Phase 5 — Large-Board UI, Accessibility, Audio, Packaging

Prereq: Phase 4 done.

## Build
- Adaptive grid, scrollable board, zoom (buttons, wheel, pinch), sticky controls, valid-destination highlight, keyboard navigation (arrows, Enter/Space). Usable at 40, 50, 60+ tubes on 1366x768, 1920x1080, and phone size.
- Accessibility: colorblind palettes, non-color cues (pattern or symbol per color), contrast checks, reduced motion.
- Audio: procedurally generated or CC0 SFX (select, pour, invalid, undo, victory, reward) plus optional music; toggles work; fully usable muted.
- Performance: profile 60-tube board, record real frame times, RepaintBoundary per tube.
- Packaging: `flutter build windows --release`, MSIX config, install/uninstall steps. Android steps marked untested unless run.
- Docs: README (one-command dev launch, production build), ARCHITECTURE, TROUBLESHOOTING, BENCHMARKS, KNOWN_LIMITATIONS.

## Done when
- Release build launches on a clean setup following README only.
- Full test suite green.
- KNOWN_LIMITATIONS lists anything incomplete, honestly.
