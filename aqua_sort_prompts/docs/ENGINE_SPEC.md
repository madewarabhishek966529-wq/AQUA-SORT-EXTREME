# Engine Spec

## State
- `capacity = 4`. A tube is a list of color ids, bottom to top. A puzzle is a list of tubes.
- Standard level: `C` colors x `capacity` units each, `E` empty tubes, total tubes = `C + E`.

## Forward move (the only player move)
`move(A -> B)` is legal iff A is non-empty, A != B, B has free space, and B is empty or top(B) == top(A).
Let `g` = length of the top contiguous run of color `c = top(A)`. Transfer `k = min(g, free(B))` units.
Solver-only pruning (not a player rule): skip pouring a full single-colored tube onto an empty tube.

## Solved
Every tube is empty, or full and single-colored. Variant: single-colored regardless of fullness. Pick one and use it consistently in game, solver, and tests.

## Reverse move (for generation)
From solved state S, a reverse move produces predecessor S' such that the forward move `A -> B` from S' yields S.

`rev(B -> A, j)` is valid iff:
1. B non-empty, A != B, `c = top(B)`.
2. `1 <= j <=` length of the top run of `c` on B.
3. A has free space `>= j`.
4. After removing `j` units, B is empty or its new top is `c` (the forward move needs B empty or top == c before the pour).
5. Either A's top in S is not `c`, or B is full in S (otherwise the forward move would pour more than `j` units).

S' = S with `j` units moved from B's top to A's top.

Always check `forward(S', A, B) == S` in the generator and tests; reject any reverse move that fails.

## Scrambling policy
- Seeded `Random(seed)`; generation settings stored in the level record.
- Apply N reverse moves, N scaled by tier; avoid immediately undoing the previous one; prefer moves that raise fragmentation (color changes along tubes).
- Solution = reverse-move list, each inverted into a forward move, in reverse order. Stored with the level.
- Reject: already solved, solution shorter than tier minimum, fragmentation below tier minimum.

## Canonicalization
Sort tubes by encoded content so tube order is irrelevant. Key = joined encoded tubes. Used for visited sets, caches, dedupe. Colors are not relabeled by default (palette identity matters in UI); the solver may relabel internally.

## Determinism
`seed + GenerationSettings` (colors, empties, capacity, scramble steps, generator version) fully reproduces a level. Bump the generator version on any change that alters output.
