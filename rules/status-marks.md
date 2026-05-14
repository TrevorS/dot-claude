# Status Marks

Per-item status (validation, test runs, CI checks, file-by-file results) uses this convention. Never use emoji checkmarks (`✅`, `❌`, `✔️`) — they violate the no-emoji default and render inconsistently.

## Marks

- `⟨✓⟩` — pass / done
- `⟨~⟩` — skip / partial / not applicable
- `⟨✗⟩` — fail / error

## Example

```
⟨✓⟩ Whitespace trimming
⟨✓⟩ File endings
⟨~⟩ Merge conflict markers
⟨✗⟩ Markdown linting
```

## When this applies

Any list of per-item status you'd otherwise mark with emoji or `[x]`/`[ ]` — validation reports, test results, CI summaries, multi-step plan completion, file-by-file results.

## Not for

- **Single-item results** — use plain text ("passed", "failed")
- **Inline narrative prose** — don't insert marks into sentences
- **Output bound for GitHub PRs / issues** — use markdown task lists `[x]`/`[ ]` so they render as real task lists in the GitHub UI
