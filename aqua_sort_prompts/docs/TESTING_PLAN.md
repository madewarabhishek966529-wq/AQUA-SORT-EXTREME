# Testing Plan

## Unit (engine)
Legal/illegal pours, capacity, partial group transfer, solved detection, serialization round trip, canonical key equivalence, generator determinism, reverse-move property (`forward(reverse(S)) == S`), solver correctness on small known puzzles, budget and cancellation, tier mapping.

## Widget
Select/deselect, invalid move leaves state unchanged, undo exactness, restart, input lock during pour, rendered liquid equals state after animation, large board layout has no overflow at 1366x768 and 1920x1080.

## Integration
Play a generated level to completion via stored solution; continue after simulated kill; daily challenge determinism; achievement unlock end to end.

## Level certification (every catalog level)
1. Validate initial state shape.
2. Obtain solution (stored and, within budget, solver-found).
3. Replay through the real `MoveValidator`.
4. Confirm solved.
5. Store seed, settings, generator version.
6. Confirm metrics match the tier.

## Performance
Benchmarks for generation and solving at 20, 40, 50, 60 tubes; frame-time profile for a 60-tube board. Record real numbers in `docs/BENCHMARKS.md` with machine specs. Never invent figures.
