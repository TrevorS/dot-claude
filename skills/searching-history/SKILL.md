---
name: searching-history
description: Search past Claude Code sessions to recall prior solutions, commands, fixes, and decisions. Use when the user references earlier work ("how did I fix", "last time we", "pick up where we left off", "a few months ago").
context: fork
model: claude-sonnet-4-5
allowed-tools: Bash
argument-hint: "<search-query>"
---

# glhf — Conversation History Search

Search your Claude Code conversation history using hybrid search (text + semantic).

When invoked as `/glhf <query>`, run: `glhf search "$ARGUMENTS" --compact`

## Quick Examples

```bash
# Find past solutions
glhf search "authentication" --compact

# Find commands you've run
glhf search "docker" -t Bash --compact

# Filter by project and time
glhf search "bug" -p myapp --since 1w --compact

# Find errors
glhf search "failed" --errors --compact

# Check recent sessions
glhf recent -l 10

# Get session overview then dive deeper
glhf session abc123 --summary
glhf session abc123 --limit 30
```

## Commands

| Command   | Purpose                               |
| --------- | ------------------------------------- |
| `search`  | Find content across all sessions      |
| `session` | View a specific session's content     |
| `recent`  | List recent sessions                  |
| `status`  | Show index stats                      |
| `index`   | Update index (incremental by default) |

## Search Flags

| Flag             | Purpose                                             |
| ---------------- | --------------------------------------------------- |
| `--compact`      | One-line output, fewer tokens                       |
| `-l`/`--limit`   | Max results to return (default 10)                  |
| `-t`/`--tool`    | Filter by tool (Bash, Read, Edit, Grep, etc.)       |
| `-p`/`--project` | Filter by project name (substring match, `.` = cwd) |
| `--since`        | Time filter (1h, 2d, 1w, or date)                   |
| `--errors`       | Only show error results                             |
| `--json`         | Machine-readable JSON output                        |

## Session Flags

| Flag           | Purpose                              |
| -------------- | ------------------------------------ |
| `--summary`    | Show session summary without content |
| `-l`/`--limit` | Show only first N messages           |
| `--json`       | Machine-readable JSON output         |

## Recommended Patterns

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

## Tips

1. **Always use `--compact`** — significantly reduces output tokens
2. **Chain commands**: search, find session ID in output, then `glhf session <id> --summary` for full context
3. **Use `-p .`** to filter to current project
4. **Use `--json`** when piping to other tools or processing programmatically
5. **Index is incremental** — `glhf index` only re-processes changed files. Use `--full` to rebuild, `--skip-embeddings` for text-only indexing
6. **Search shows staleness hints** — if the index is behind, it prints how many files changed. Run `glhf index` to update
