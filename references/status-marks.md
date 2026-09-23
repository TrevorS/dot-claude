# Status Marks Layout Reference

Layout detail for `~/.claude/rules/status-marks.md`, which is always loaded and holds the marks, indicators, and never-list. Read this before a multi-block status report.

## Linked labels

Put plain text inside the link, because code styling overrides link color:

❨`✓`❩ [Format and Lint Check](https://...) · `✓` 9/9

If the SHA itself is the label, choose one: link color (`[79ed823](url)`) or code color
(`` `79ed823` `` plus a separate link). You can't have both on one span. Skip the link
entirely when there's no actionable URL.

## Layout

**Single-line** with `·` interpunct, for terse status:

❨`✓`❩ Action `→` target · `↑` N `↓` N · `⏱` Xm · `✓` N/N

**Multi-line line-items**, when detail matters:

❨`✓`❩ Diff · `↑` 213 `↓` 15 across 5 files
❨`✓`❩ Commits · 2 `→` master (`79ed823`, `637f804`)
❨`✓`❩ CI · `⏱` 7m, `✓` 9/9 jobs

**Tables**, for 3+ rows of comparable data:

| Commit    | Diff           | Time   | Jobs    |
| --------- | -------------- | ------ | ------- |
| `637f804` | `↑` 213 `↓` 15 | `⏱` 7m | `✓` 9/9 |
| `79ed823` | `↑` 200 `↓` 0  | `⏱` 5m | `✓` 9/9 |

**Blockquotes**, for small amounts of text only (a one-liner banner, a brief callout).
Wide content in a blockquote pushes text too far right and reads poorly.

Markdown collapses internal whitespace; don't rely on visual column alignment with
spaces.

## Continuation lines

When detail under a status line would wrap past one terminal row, split it onto
continuation lines instead of wrapping or joining clauses with `;`.

- `` `├─` `` / `` `╰─` `` for plain detail (non-last / last child)
- `` `├─▶` `` / `` `╰─▶` `` when the child is a result or action

Indent the branch glyph by one space so it sits under the `✓` of `❨✓❩`; the leading
space goes *outside* the code span. Leave a blank line after the last child.

❨`✓`❩ Push · `0da48f3d` `→` `master`
 `├─▶` 6 files (`↑` 15 `↓` 148)
 `╰─▶` CI run #25952834388 triggered

Branch glyphs stand alone; never wrap them in `❨ ❩`.

## Categorical lists

For multi-item *proposals* (fix lists, findings, change packages), use flat bullets
grouped by intent rather than chronology, each group led by a short label line such as
`Bugs:`. Pick contrasting categories (Bugs/Polish, Must/Nice, Blocker/Follow-up); two
crisp groups beat four vague ones. Keep each bullet to one rendered line.

Reserve the continuation tree above for parent-child *status reporting*, meaning one
status mark with sub-results, not for any multi-item list.
