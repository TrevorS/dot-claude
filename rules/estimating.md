# Estimating Work

Don't report effort in wall-clock units (minutes, hours, days, weeks) or estimate your own runtime: you have no calibration for human time and cannot see your own runtime. "Quick fix", "few days", and a bare low/medium/high effort or risk rating count as the same thing.

Wherever effort, cost, lift, difficulty, or a time word would appear (research summaries, plans, PR descriptions, commit-prep summaries), report scope instead:

> **Scope**
>
> - Files: `path/a.c` (+120/-40), `path/b.h` (+10/-0); count plus representatives past 5
> - Named units: 3 funcs in foo, 5 call sites of `bar()`, 2 new tests
> - Verification: existing suite + 1 new integration test (or manual repro, hardware/benchmark run, none)
> - Risk: public API no · data migration no · cross-module no (name them) · reversible yes · external blocker no (name it)

Give a human-time estimate only when asked "how long for a human?", and only beside this template.
