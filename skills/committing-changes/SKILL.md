---
name: committing-changes
description: Stage, validate, and commit changes with a clear message, optionally pushing to remote and monitoring CI. Use when committing code, creating a commit, pushing changes, or doing a commit-and-push workflow.
when_to_use: "Typed as 'commit this', 'commit and push', 'ship it', or after finishing a unit of work with a dirty tree. Not for rewriting existing commits — that is cleaning-commit-history."
argument-hint: "[--push] [message hint]"
---

# Committing Changes

Auto-stage, validate, and commit changes. Pass `--push` to also push and monitor CI.

## Workflow

### 1. Detect VCS

`jj root` decides; jj is preferred.

### 2. Check Branch Safety

Check `./CLAUDE.md` **and** `./.claude/CLAUDE.md` for a `direct-commits-allowed: true` marker. It is the documented exception to the default "branch first when on the default branch"; without it, suggest a feature branch.

### 3. Run Validation

Auto-detect project type and run: format -> lint -> typecheck. Stop on failure.
Prefer the repo's own gate when it has one (`make validate` in `~/.claude`),
otherwise load `validating-project`.

**This step is mandatory on the jj path, not best-effort.** jj has no hook system
and does not run git's hooks even in a colocated repo, so `.git/hooks/pre-commit`
never fires on `jj describe` / `jj commit`. Whatever that hook would have caught
is caught here or not at all. On the git path the hook still runs — re-stage once
and retry if it rewrites files (see step 6).

`jj fix` is not a substitute: it only pipes file content through a tool and keeps
what comes back, so it can carry formatters (`ruff format`, `stylua`) but never
report-only checks (`ruff check`, `ty`, `luacheck`, hook tests).

### 4. Craft Commit Message

This is the canonical commit-message spec (`cleaning-commit-history` points here).

```text
<type>(<scope>): <imperative subject, under 72 chars>

- <what changed and why>
```

Types: `feat`, `fix`, `refactor`, `docs`, `style`, `perf`, `test`, `build`, `ci`, `chore`. Scope is optional but encouraged for multi-module repos. Focus on the "why" not the "what".

### 5. Commit

**jj workflow (preferred)**:

```bash
jj status && jj diff --stat
jj describe -m "feat: message here"
```

**git workflow (fallback)**:

```bash
git add <specific-files>
git commit -F <scratchpad>/commit-msg.txt
```

Write the message to a scratchpad file rather than quoting it inline (avoids shell escaping). Use the session scratchpad directory given in the environment context — not `/tmp`. There is no env var for it; substitute the literal path. Handle pre-commit hook failures by re-staging and retrying once.

### 6. Push (if --push or explicitly requested)

PR-safety check first (`rules/pr-safety.md`): plain new commits on top are always safe; a push that rewrites reviewed commits needs a go-ahead.

**jj** (`-r @` not `-r @-`, see `using-jj`):

```bash
jj bookmark set <branch> -r @
jj git push --bookmark <branch>
```

**git**:

```bash
git push -u origin HEAD
```

### 7. Monitor CI (after push)

If `.github/workflows/` exists and `ci=github-actions` in hook output:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name>
```

Do not pre-resolve the SHA (`monitoring-ci` explains the `@-` trap). Background it from here with `run_in_background: true`; the main session receives the notification.

## Recovery

- Re-stage once if pre-commit hooks fail (git only)
- For jj: use `jj op restore` if something goes wrong
