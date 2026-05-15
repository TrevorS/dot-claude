# Status Marks & Indicators

Conventions for per-item status lines, diff/duration indicators, and report layout. Many GFM features don't render in the Claude Code TUI for this terminal/theme — these rules pick the subset that actually displays distinctly.

## Status marks

- ⟨`✓`⟩ — pass / done
- ⟨`~`⟩ — skip / partial / not applicable
- ⟨`✗`⟩ — fail / error

Always wrap the inner flag in inline code; keep the math angle brackets plain. Never use emoji checkmarks (`✅`, `❌`, `✔️`) — they render inconsistently and violate the no-emoji default.

## Example

⟨`✓`⟩ Validate — *9/9 passed*
⟨`~`⟩ Cooldown — *active until 00:35*
⟨`✗`⟩ Push — *blocked by hook*

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
- *`italic-code`* — italic wrapping a code span; both render together for emphasis on terse data

Don't rely on bold — it renders identical to plain in this terminal/theme.

## Linked labels

When the label points to a clickable target (commit, PR, CI run, issue, file in repo), put plain text inside the link — code styling overrides link color:

⟨`✓`⟩ [Format and Lint Check](https://...) — `✓` 9/9

If the SHA itself is the label, choose: link color (`[79ed823](url)`) or code color (`` `79ed823` `` + separate link elsewhere). Can't have both on one span.

Don't link without an actionable target. Skip the markdown link if no useful URL.

## Layout

**Single-line with `·` interpunct** — for terse status:

⟨`✓`⟩ Action `→` target · `↑` N `↓` N · `⏱` Xm · `✓` N/N

**Multi-line line-items** — when detail matters:

⟨`✓`⟩ Diff — `↑` 213 `↓` 15 across 5 files
⟨`✓`⟩ Commits — 2 `→` master (`79ed823`, `637f804`)
⟨`✓`⟩ CI — `⏱` 7m, `✓` 9/9 jobs

Markdown collapses internal whitespace; don't rely on visual column alignment with spaces.

**Tables** — for 3+ rows of comparable data:

| Commit    | Diff           | Time   | Jobs    |
| --------- | -------------- | ------ | ------- |
| `637f804` | `↑` 213 `↓` 15 | `⏱` 7m | `✓` 9/9 |
| `79ed823` | `↑` 200 `↓` 0  | `⏱` 5m | `✓` 9/9 |
| `092d4bd` | `↑` 12 `↓` 4   | `⏱` 3m | `✓` 9/9 |

**Blockquotes** — small amounts of text only (a one-liner banner, a brief callout). Wide content in a blockquote pushes text too far right and reads poorly. Don't blockquote multi-paragraph or wide content.

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

## When this applies

Any per-item status list — validation reports, test results, CI summaries, multi-step plan completion, file-by-file results, commit-prep summaries.

## Not for

- **Single-item results** — use plain text ("passed", "failed") in a sentence
- **Inline narrative prose** — don't insert marks into running sentences
- **Output bound for GitHub PRs / issues** — use native task lists `[x]`/`[ ]` so they render as real checklists in the GitHub UI
