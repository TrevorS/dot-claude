# Status Marks & Indicators

Conventions for per-item status lines and diff/duration indicators in the Claude Code TUI.

Layout galleries, linked-label rules, continuation-tree syntax, and proposal-list layout live in `~/.claude/references/status-marks.md` (not auto-loaded). Read it when composing a multi-block report.

## Status marks

- ❨`✓`❩ pass / done
- ❨`~`❩ skip / partial / not applicable
- ❨`✗`❩ fail / error

Always wrap the inner flag in inline code; keep the parenthesis ornaments (`❨` U+2768 / `❩` U+2769) plain. Never use emoji checkmarks (`✅`, `❌`, `✔️`); they render inconsistently and violate the no-emoji default.

❨`✓`❩ Validate · *9/9 passed*

## Indicators

Style only the glyph; leave the number plain.

- **Lines added / removed**: `` `↑` `` N · `` `↓` `` N (e.g., `↑` 213 `↓` 15)
- **Diff hunk signs**: `` `+` ``N · `` `-` ``N tight, no space (e.g., `+`200 / `-`15)
- **Duration**: `` `⏱` `` Xm Ys (e.g., `⏱` 7m 14s)
- **Direction / flow**: `` `→` `` target (e.g., 2 commits `→` master)
- **Outcome count**: `` `✓` `` N/N or `` `✗` `` N/N (e.g., `✓` 9/9)

Glyphs need a space before the number (`` `↑` `` 213, not `` `↑` ``213). Diff signs are tight (`` `+` ``200, not `` `+` `` 200).

## Detail styling

*italic* for descriptive prose, `code` for terse data (paths, identifiers, SHAs).

## Never (silently broken in this terminal)

HTML tags (`<u>`, `<kbd>`, `<mark>`), ANSI escape codes, italic on the `⏱` stopwatch glyph, italic inside an inline code span (`` `*x*` ``), and link text wrapped in code (`` [`text`](url) ``).

## When this applies

Any per-item status list: validation reports, test results, CI summaries, plan completion, file-by-file results. Not for single-item results (plain prose) or inline sentences. The `→` glyph is the one deliberate exception to the no-arrows writing rule; separate a label from its detail with `·`, not an em-dash. Output bound for GitHub PRs and issues uses native task lists `[x]`/`[ ]` so they render as checklists there.
