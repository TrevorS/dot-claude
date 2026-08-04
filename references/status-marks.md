# Status Marks Quick Reference

Compact subset of `status-marks.md` for skills to reference when formatting status output. Read this before producing per-item reports.

## Marks

- ❨`✓`❩ — pass / done
- ❨`~`❩ — skip / partial / not applicable
- ❨`✗`❩ — fail / error

Wrap only the inner flag in inline code; keep the parenthesis ornaments (`❨` U+2768 / `❩` U+2769) plain. Never use emoji checkmarks (`✅`, `❌`, `✔️`).

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

## Linked labels

Put plain text inside the link — code styling overrides link color:

❨`✓`❩ [Format and Lint Check](https://...) — `✓` 9/9

If the SHA itself is the label, choose one: link color (`[79ed823](url)`) or code color
(`` `79ed823` `` plus a separate link). You can't have both on one span. Skip the link
entirely when there's no actionable URL.

## Layout

**Single-line with `·` interpunct** — terse status:

❨`✓`❩ Action `→` target · `↑` N `↓` N · `⏱` Xm · `✓` N/N

**Multi-line line-items** — when detail matters:

❨`✓`❩ Diff — `↑` 213 `↓` 15 across 5 files
❨`✓`❩ Commits — 2 `→` master (`79ed823`, `637f804`)
❨`✓`❩ CI — `⏱` 7m, `✓` 9/9 jobs

**Tables** — 3+ rows of comparable data:

| Commit    | Diff           | Time   | Jobs    |
| --------- | -------------- | ------ | ------- |
| `637f804` | `↑` 213 `↓` 15 | `⏱` 7m | `✓` 9/9 |
| `79ed823` | `↑` 200 `↓` 0  | `⏱` 5m | `✓` 9/9 |

**Blockquotes** — small amounts of text only (a one-liner banner, a brief callout).
Wide content in a blockquote pushes text too far right and reads poorly.

Markdown collapses internal whitespace; don't rely on visual column alignment with
spaces.

## Continuation lines

When detail under a status line would wrap past one terminal row, split it onto
continuation lines instead of wrapping or joining clauses with `;`.

- `` `├─` `` / `` `╰─` `` — plain detail (non-last / last child)
- `` `├─▶` `` / `` `╰─▶` `` — when the child is a result or action

Indent the branch glyph by one space so it sits under the `✓` of `❨✓❩`; the leading
space goes *outside* the code span. Leave a blank line after the last child.

❨`✓`❩ Push — `0da48f3d` `→` `master`
 `├─▶` 6 files (`↑` 15 `↓` 148)
 `╰─▶` CI run #25952834388 triggered

Branch glyphs stand alone — never wrap them in `❨ ❩`.

## Categorical lists

For multi-item *proposals* (fix lists, findings, change packages) use flat bullets
grouped under real `####` headings, grouped by intent rather than chronology. Pick
contrasting categories (Bugs/Polish, Must/Nice, Blocker/Follow-up); two crisp groups
beat four vague ones. Keep each bullet to one rendered line.

Reserve the continuation tree above for parent-child *status reporting* — one status
mark with sub-results — not for any multi-item list.

## Don't

`**bold**`, `~~strikethrough~~`, task lists `- [x]`, HTML tags, ANSI escapes,
mid-content headers below H3, wrapping link text in code (`` [`text`](url) ``),
italic inside a code span, and list-item continuation indent (bullets collapse
continuation lines flush-left regardless of source indent).

See `~/.claude/rules/status-marks.md` for the full rule with rationale and examples.
