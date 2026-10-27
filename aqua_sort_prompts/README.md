# Aqua Sort: Extreme — Prompt Pack

Flutter/Dart color-sorting puzzle game with 40–60+ tube boards.

## Contents
- `00_MASTER_PROMPT.md` — shared context and fixed decisions (paste first in every session)
- `phases/` — five phase prompts, run in order
- `docs/` — engine spec, difficulty metrics, architecture, testing plan, troubleshooting, prompt review
- `original/MASTER_PROMPT_ORIGINAL.md` — your original prompt

## How to use
1. Start a session with `00_MASTER_PROMPT.md`, then attach `docs/` files the phase references.
2. Run `phases/PHASE_1_ENGINE.md`. Verify its "Done when" list yourself.
3. Continue phase by phase. Start each phase in a fresh session with the master prompt plus the phase file and the current repo.
4. Keep `docs/BENCHMARKS.md` as real measured data only.
