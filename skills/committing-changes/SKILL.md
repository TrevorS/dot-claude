---
name: committing-changes
description: Stage, validate, and commit changes with a clear message, optionally pushing to remote and monitoring CI. Use when committing code, creating a commit, pushing changes, or doing a commit-and-push workflow.
when_to_use: "Typed as 'commit this', 'commit and push', or 'ship it'. Not for rewriting existing commits — that is cleaning-commit-history."
argument-hint: "[--push] [message hint]"
---

# Committing Changes

Auto-stage, validate, and commit changes. Pass `--push` to also push and monitor CI.

## Workflow

### 1. Run Validation

Validate before committing; a failure stops the commit.
Prefer the repo's own gate (`make validate` in `~/.claude`; else a check/lint/test
script or pre-commit). Otherwise run format → lint → typecheck → test and stop at
the first failure.

**This step is mandatory on the jj path, not best-effort.** jj has no hook system
and does not run git's hooks even in a colocated repo, so `.git/hooks/pre-commit`
never fires on `jj describe` / `jj commit`. Whatever that hook would have caught
is caught here or not at all.

`jj fix` is not a substitute: it only pipes file content through a tool and keeps
what comes back, so it can carry formatters (`ruff format`, `stylua`) but never
report-only checks (`ruff check`, `ty`, `luacheck`, hook tests).

### 2. Craft Commit Message

This is the canonical commit-message spec (`cleaning-commit-history` points here).

```text
<type>(<scope>): <imperative subject, under 72 chars>

- <what changed and why>
```

Types: `feat`, `fix`, `refactor`, `docs`, `style`, `perf`, `test`, `build`, `ci`, `chore`. Scope is optional but encouraged for multi-module repos.

### 3. Commit

**jj workflow (preferred)** — jj when `jj root` succeeds, else git:

```bash
jj describe -m "feat: message here"
```

**git workflow (fallback)**: `git add <files> && git commit -F <scratchpad>/commit-msg.txt`

There is no env var for the scratchpad directory; substitute the literal path from the environment context.

### 4. Push (if --push or explicitly requested)

**jj** (`-r @` not `-r @-`, see `using-jj`):

```bash
jj bookmark set <branch> -r @
jj git push --bookmark <branch>
```

### 5. Monitor CI (after push)

Follow `rules/ci-monitoring.md`.
