# Estimating Work

Never report effort in wall-clock units (minutes/hours/days/weeks). You have no calibration for human time and cannot see your own runtime. Replace time with countable units.

## Banned

- "X days/hours/minutes", "quick fix", "few days"
- "Low/medium/high effort" or "low/medium/high risk" as the whole answer
- Estimating your own runtime. If asked, decline and give the scope template instead.

## Required units

When you'd reach for an effort word, report:

- **Files** — paths touched (or count + representatives if >5)
- **LOC delta** — approx `+added/-removed`, rounded
- **Named units** — functions, kernels, symbols, call sites, tests, migrations
- **Verification** — existing tests / new tests needed / manual repro / hardware or benchmark run / none
- **Risk axes** — yes/no flags, not adjectives: public API change · data migration · cross-module (name them) · reversible · external blocker (name it)

## When this applies

Research and survey summaries, plans in ExitPlanMode, PR descriptions, commit-prep summaries — anywhere "effort", "cost", "lift", "difficulty", or a time word would otherwise appear.

## Template

> **Scope**
> - Files: `path/a.c` (+120/-40), `path/b.h` (+10/-0)
> - Named units: 3 funcs in foo, 5 call sites of `bar()`, 2 new tests
> - Verification: existing suite + 1 new integration test
> - Risk: public API no · data migration no · cross-module no · reversible yes · external blocker no

## Bad → good

Bad:
> Port cost: ~580 LOC across 5-7 kernels + host driver. Effort 4-6 days. Low-medium risk — kernels are self-contained.

Good:
> **Port scope**
> - Files: `ds4_cuda.cu` (+580/-0)
> - Named units: 5 kernels (`moe_gate_up_mid_expert_tile8_rowspan_kernel<512|1024|2048>`, `moe_down_expert_tile16_row2048_kernel`, `moe_build_expert_tile_offsets_kernel`, `moe_build_expert_tiles_kernel`) + host driver pipeline
> - Verification: existing MoE prefill regression suite + H100 perf run
> - Risk: public API no · data migration no · cross-module no (self-contained) · reversible yes · external blocker no

## Human-time estimates

Only if the user explicitly asks "how long for a human?", and only paired with the scope template above so the structural reality is visible alongside the guess.
