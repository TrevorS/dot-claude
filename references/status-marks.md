# Status Marks Quick Reference

Compact subset of `status-marks.md` for skills to reference when formatting status output. Read this before producing per-item reports.

## Marks

- ❨`✓`❩ — pass / done
- ❨`~`❩ — skip / partial / not applicable
- ❨`✗`❩ — fail / error

Wrap only the inner flag in inline code; keep the math angle brackets plain. Never use emoji checkmarks (`✅`, `❌`, `✔️`).

## Indicators (style only the glyph; leave the number plain)

- `` `↑` `` N · `` `↓` `` N — lines added / removed (e.g., `↑` 213 `↓` 15)
- `` `+` ``N · `` `-` ``N — diff hunk signs (tight, no space — e.g., `+`200)
- `` `⏱` `` Xm Ys — duration (e.g., `⏱` 7m 14s)
- `` `→` `` target — flow / direction (e.g., 2 commits `→` master)
- `` `✓` `` N/N — outcome count (e.g., `✓` 9/9)

Glyphs need a space before the number (`` `↑` `` 213, not `` `↑` ``213). Diff signs are tight.

## Detail styling

- *italic* — descriptive prose ("*9/9 passed*", "*active until 00:35*")
- `code` — terse data, paths, identifiers, SHAs

Don't rely on bold — renders identical to plain in this terminal.

## Layout

- Single-line with `·` interpunct for terse status
- Multi-line line-items when detail matters
- Tables for 3+ rows of comparable data
- Blockquotes only for small text

## Don't

`**bold**`, `~~strikethrough~~`, task lists `- [x]`, HTML tags, ANSI escapes, mid-content headers below H3, wrapping link text in code (`` [`text`](url) ``).

See `status-marks.md` for the full rule with rationale and examples.
