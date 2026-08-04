# Status Marks & Indicators

Conventions for per-item status lines and diff/duration indicators. Many GFM features don't render in the Claude Code TUI for this terminal/theme — these rules pick the subset that displays distinctly.

Layout galleries, worked examples, and the full rationale live in `~/.claude/references/status-marks.md` (not auto-loaded). Read it when composing a multi-block report; skills in a fork context should reference it rather than this file.

## Status marks

- ❨`✓`❩ — pass / done
- ❨`~`❩ — skip / partial / not applicable
- ❨`✗`❩ — fail / error

Always wrap the inner flag in inline code; keep the parenthesis ornaments (`❨` U+2768 / `❩` U+2769) plain. Never use emoji checkmarks (`✅`, `❌`, `✔️`) — they render inconsistently and violate the no-emoji default.

❨`✓`❩ Validate — *9/9 passed*
❨`~`❩ Cooldown — *active until 00:35*
❨`✗`❩ Push — *blocked by hook*

## Indicators

Style only the glyph; leave the number plain.

- **Lines added / removed** — `` `↑` `` N · `` `↓` `` N (e.g., `↑` 213 `↓` 15)
- **Diff hunk signs** — `` `+` ``N · `` `-` ``N tight, no space (e.g., `+`200 / `-`15)
- **Duration** — `` `⏱` `` Xm Ys (e.g., `⏱` 7m 14s)
- **Direction / flow** — `` `→` `` target (e.g., 2 commits `→` master)
- **Outcome count** — `` `✓` `` N/N or `` `✗` `` N/N (e.g., `✓` 9/9)

Glyphs need a space before the number (`` `↑` `` 213, not `` `↑` ``213). Diff signs are tight (`` `+` ``200, not `` `+` `` 200).

## Detail styling

- *italic* — descriptive prose ("*9/9 passed*", "*active until 00:35*")
- `code` — terse data, file paths, identifiers, SHAs
- *`italic-code`* — italic wrapping a code span; both render together

Don't rely on bold — it renders identical to plain in this terminal/theme.

When the label points to a clickable target (commit, PR, CI run, issue), put **plain text** inside the link — code styling overrides link color:

❨`✓`❩ [Format and Lint Check](https://...) — `✓` 9/9

Don't link without an actionable target.

## Splitting long detail

Detail that would wrap past one terminal row goes on continuation lines — never joined with `;` and never stuffed into a parenthetical:

- `` `├─` `` / `` `╰─` `` — plain detail (non-last / last child)
- `` `├─▶` `` / `` `╰─▶` `` — when the child is a result or action

Indent the glyph one space so it sits under the `✓` (the space goes *outside* the code span); leave a blank line after the last child; never wrap branch glyphs in `❨ ❩`.

For multi-item *proposals* (fix lists, findings, change packages) use flat bullets under real `####` headings grouped by intent — not the branch tree, which is for one status mark with its sub-results. Layout options (single-line `·`, multi-line line-items, tables, blockquotes) are in the reference.

## Anti-patterns (silently broken in this terminal)

- `**bold**` — renders identical to plain
- `~~strikethrough~~` — not rendered
- `- [x]` / `- [ ]` task lists — silently stripped
- Mid-content headers below H3 — collapse to bold (= plain)
- `<u>`, `<kbd>`, `<mark>`, other HTML tags — not rendered
- ANSI escape codes from the model — not rendered
- Italic on the ⏱ stopwatch glyph specifically — doesn't slant; use code wrap only
- Italic inside an inline code span (`` `*x*` ``) — markers shown literally
- Wrapping link text in inline code (`` [`text`](url) ``) — code color wins, link color lost
- List-item continuation indent — bullets collapse continuation lines flush-left regardless of source indent. Keep bullets to one rendered line; if it would wrap, split it or drop out of the list.

## When this applies

Any per-item status list — validation reports, test results, CI summaries, multi-step plan completion, file-by-file results, commit-prep summaries.

## Not for

- **Single-item results** — use plain text ("passed", "failed") in a sentence
- **Inline narrative prose** — don't insert marks into running sentences
- **Output bound for GitHub PRs / issues** — use native task lists `[x]`/`[ ]` so they render as real checklists in the GitHub UI
