# glhf Reference

Full command and flag reference for conversation history search. Load when you need a
flag that isn't in `SKILL.md`'s core usage block.

## Commands

| Command   | Purpose                               |
| --------- | ------------------------------------- |
| `search`  | Find content across all sessions      |
| `session` | View a specific session's content     |
| `recent`  | List recent sessions                  |
| `status`  | Show index stats                      |
| `index`   | Update index (incremental by default) |

## Search flags

| Flag             | Purpose                                             |
| ---------------- | --------------------------------------------------- |
| `--compact`      | One-line output, fewer tokens                       |
| `-l`/`--limit`   | Max results to return (default 10)                  |
| `-t`/`--tool`    | Filter by tool (Bash, Read, Edit, Grep, etc.)       |
| `-p`/`--project` | Filter by project name (substring match, `.` = cwd) |
| `--since`        | Time filter (1h, 2d, 1w, or date)                   |
| `--errors`       | Only show error results                             |
| `--json`         | Machine-readable JSON output                        |

## Session flags

| Flag           | Purpose                              |
| -------------- | ------------------------------------ |
| `--summary`    | Show session summary without content |
| `-l`/`--limit` | Show only first N messages           |
| `--json`       | Machine-readable JSON output         |

## Recommended patterns

**Find past solutions:**

```bash
glhf search "problem description" --compact
glhf search "specific keyword" --compact
glhf session <id> --summary
```

**Recall commands:**

```bash
glhf search "git rebase" -t Bash --compact
glhf search "cargo" -t Bash --since 1w --compact
```

**Find errors:**

```bash
glhf search "error" --errors --since 1d --compact
```

**Browse recent work:**

```bash
glhf recent -l 10
glhf recent -p myproject
```

## Notes

- Use `-p .` to filter to the current project.
- Use `--json` when piping to other tools or processing programmatically.
- The index is incremental — `glhf index` only re-processes changed files. `--full`
  rebuilds; `--skip-embeddings` does text-only indexing.
- Search prints staleness hints: if the index is behind, it reports how many files
  changed. Run `glhf index` to update.
- The index database lives in `~/Library/Caches/glhf/` and outlives Claude Code's own
  transcript retention, so sessions older than the transcript-cleanup window remain
  searchable.
