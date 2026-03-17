---
name: searching-history
description: >-
  Search Claude Code conversation history and tool logs to find past solutions,
  recall commands, and discover related work. Use when the user mentions past
  sessions, asks "have I done this before", "how did I", "what command did I
  run", or needs to find previous implementations, error resolutions, debugging
  approaches, or configuration changes. Also use proactively before proposing
  solutions — check if a similar problem was already solved.
allowed-tools: Bash
argument-hint: "<search-query>"
---

# glhf — Conversation History Search

Search your Claude Code conversation history using hybrid search (text + semantic).

When invoked as `/glhf <query>`, run: `glhf search "$ARGUMENTS" --mode semantic --compact`

## Quick Examples

```bash
# Find past solutions (semantic search)
glhf search "authentication" --mode semantic --compact

# Find commands you've run
glhf search "docker" -t Bash --compact

# Regex search for exact error messages
glhf search -e "ECONNREFUSED|ETIMEDOUT" --compact

# Search with context (like grep -C)
glhf search "panic" -C 2 --compact

# Check recent sessions
glhf recent -l 10

# Get session overview then dive deeper
glhf session abc123 --summary
glhf session abc123 --limit 50
```

## Commands

| Command    | Purpose                              |
| ---------- | ------------------------------------ |
| `search`   | Find content across all sessions     |
| `session`  | View a specific session's content    |
| `related`  | Find sessions similar to a given one |
| `recent`   | List recent sessions                 |
| `projects` | List all indexed projects            |
| `status`   | Show index stats                     |
| `index`    | Rebuild the search index             |

## Key Search Flags

| Flag                     | Purpose                                       |
| ------------------------ | --------------------------------------------- |
| `--compact`              | One-line output, fewer tokens                 |
| `--mode semantic`        | Conceptual search (how to X, patterns)        |
| `--mode text`            | Exact keyword matching                        |
| `-e`/`--regex`           | Regex pattern matching (like grep -e)         |
| `-i`/`--ignore-case`     | Case-insensitive (for regex mode)             |
| `-A N`/`-B N`/`-C N`     | Context lines after/before/around matches     |
| `-t Bash`                | Filter by tool (Bash, Read, Edit, Grep, etc.) |
| `-p .`                   | Filter to current project                     |
| `-X name`                | Exclude a project by name (repeatable)        |
| `--since 1d`             | Time filter (1h, 2d, 1w, or date)             |
| `--errors`               | Only show error results                       |
| `--messages-only`        | Exclude tool calls                            |
| `--tools-only`           | Exclude messages                              |
| `--show-session-id`      | Include session IDs for follow-up             |
| `--json`                 | Machine-readable JSON output                  |
| `--scores`               | Show relevance scores                         |
| `--oldest`               | Reverse sort (oldest first)                   |
| `--include-this-project` | Override auto-exclusion of current project    |
| `--include-this-session` | Override auto-exclusion of current session    |
| `--this-session`         | Filter to current session only                |

## Recommended Patterns

**Find past solutions:**

```bash
glhf search "problem description" --mode semantic --compact
glhf search "specific keyword" --show-session-id --compact
glhf session <id> --summary
```

**Recall commands:**

```bash
glhf search "git rebase" -t Bash --compact
glhf search "cargo" -t Bash --since 1w --compact
```

**Regex search for exact errors:**

```bash
glhf search -e "thread.*panicked" --compact
glhf search -e "error\[E\d+\]" -i --compact
```

**Find similar work:**

```bash
glhf recent -l 10
glhf related <session-id> --limit 5
```

**Debug past errors:**

```bash
glhf search "error" --errors --since 1d --compact
```

**Cross-project search (override auto-exclusion):**

```bash
glhf search "auth" --include-this-project --compact
glhf search "deploy" -X stable -X dotfiles --compact
```

## Tips

1. **Always use `--compact`** — significantly reduces output tokens
2. **Use `--mode semantic`** for "how to" questions and conceptual searches
3. **Use `-e` (regex)** for exact error messages and patterns
4. **Chain commands**: search → get session ID → view summary → get full context
5. **Current project/session auto-excluded** when running inside Claude Code — use `--include-this-project` or `--include-this-session` to override
6. **Use `-p .`** to filter to current project when you want to include it
7. **Use `--json`** when piping to other tools or processing programmatically
8. **Index with `--skip-embeddings`** for fast text-only reindex
