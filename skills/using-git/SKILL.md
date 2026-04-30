---
name: using-git
description: Advanced git history operations and recovery — reflog for lost commits, cherry-pick with conflicts, revert on shared history, non-interactive `reset --soft` squash, aborting/recovering from rebases, stash across branches, pre-commit hook cycles. Prefers safe, non-interactive approaches. Skip for basic commit/push/branch/gitignore.
---

# Git Workflow

Safe, non-interactive approaches for squashing commits and rebasing feature branches.

> **Tip**: If jj is available (`jj root` succeeds), prefer using-jj -- it's simpler and has automatic safety via oplog.

## Squash N Commits

```bash
git reset --soft HEAD~3
git commit -m "Your consolidated message"
```

That's it. The `--soft` flag keeps your changes staged and ready to commit.

## Rebase Feature Branch

Update dev first, then rebase:

```bash
git fetch origin dev && git checkout dev && git pull
git checkout my-feature
git rebase --committer-date-is-author-date dev
git push -f origin my-feature
```

The `--committer-date-is-author-date` flag puts your feature commits on top chronologically.

## Key Safety Rules

- **Never rebase shared branches** — only rebase local feature branches
- **Don't rewrite history on a PR with review comments without asking Teej** — rebase/squash/amend/force-push detaches comments from their line anchors. Default to a new commit on top. See `rules/version-control.md`.
- **Check `git status` first** — confirm no uncommitted changes
- **Create a backup branch**: `git branch backup-$(date +%s)`
- **Review changes** before committing: `git diff --cached`

## Pre-Commit Hook Changes

If hooks modify files during commit, stage and amend:

```bash
git add .
git commit --amend --no-edit
```

## When Things Go Wrong

```bash
git rebase --abort              # Stop rebase, go back
git reflog                      # See recent commits
git reset --hard <commit-hash>  # Recovery
```

See REFERENCE.md for detailed workflows and troubleshooting.
