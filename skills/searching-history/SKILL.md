---
name: searching-history
description: Search past Claude Code sessions to recall prior solutions, commands, fixes, and decisions. Use when the user references earlier work ("how did I fix", "last time we", "pick up where we left off", "a few months ago", "what was that … I set up", "didn't I once").
argument-hint: "<search-query>"
---

# glhf — Conversation History Search

Search Claude Code conversation history using hybrid search (text + semantic).

Full command list, every flag, and per-task patterns: `REFERENCE.md`.

## How to run it (read this first)

Figure out the search query yourself, then run `glhf search` — **never run it empty and never bounce the question back to the user.**

- **Explicit `/searching-history <query>`** → use `$ARGUMENTS` as the query: `glhf search "$ARGUMENTS" --compact`
- **Auto-triggered from the conversation** → `$ARGUMENTS` is empty. Derive concise search terms from what the user is trying to recall (the topic, error text, command, or project they referenced) and run the search with those. Do not ask them to restate it.

Example: user says *"what was that cargo alias I set up?"* → run `glhf search "cargo alias" -t Bash --compact`. Then read the hits and answer; chain into `glhf session <id> --summary` if you need fuller context.

## Core usage

```bash
glhf search "authentication" --compact              # find past solutions
glhf search "docker" -t Bash --compact              # find commands you've run
glhf search "bug" -p myapp --since 1w --compact     # scope by project and time
glhf search "failed" --errors --compact             # only errors
glhf recent -l 10                                   # browse recent sessions
glhf session abc123 --summary                       # overview, then dive deeper
```

**Always pass `--compact`** — it significantly reduces output tokens. Chain search → session ID → `glhf session <id> --summary` when you need fuller context than the hits give.
