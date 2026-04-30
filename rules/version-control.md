# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface. Load `using-jj` or `using-git` skill for advanced workflows (revsets, absorb, oplog recovery, reflog, rebase recovery, cherry-pick with conflicts).

## Non-interactive jj (critical)

Always pass `-m` — unset opens an editor and blocks the agent:

```bash
jj new -m "msg"
jj describe -m "msg"
jj commit -m "msg"
jj squash -m "msg"
```

Never use `jj split`, `jj squash -i`, or `jj diffedit` — no non-interactive mode.

## Core concepts

- Working copy = commit. Every file edit is tracked in `@`. No staging area, no `git add`.
- `@` = current change, `@-` = parent, `@--` = grandparent.
- Change IDs (e.g. `kpqxywon`) are stable across rewrites. Use these, not commit hashes.
- Conflicts are state, not emergencies — jj records them in commits and rebase still succeeds.

## git essentials

- Use Write tool for commit messages (avoids shell escaping issues).
- Pre-commit hooks modify files during commit — re-stage and retry.
- `git reset --soft HEAD~N` to squash N commits non-interactively.
- Never rebase shared branches.

## Don't rewrite history on a reviewed PR without asking

If a branch already has an open PR **and any review comments, review threads, or inline comments**, do NOT rebase, squash, amend, force-push, `jj squash --into`, or otherwise rewrite its commits without explicit permission. Rewriting history detaches existing review comments from their line anchors and makes the discussion hard or impossible to follow.

Before any history-rewriting operation on a PR branch:

1. Check whether a PR exists (`gh pr view <branch>` or check the bookmark).
2. If yes, check for review comments (`gh pr view <branch> --json reviews,comments` — non-empty `reviews` or `comments`).
3. If there are comments, **stop and ask Teej** before rewriting. Default to adding new commits on top (`jj new` + `jj git push`, or `git commit` + `git push`) so review threads stay anchored.
4. Force-pushing is allowed only when (a) Teej confirms, or (b) the PR has zero review activity.

This applies equally to jj (`jj squash`, `jj rebase`, `jj abandon` of pushed changes, `--ignore-immutable`) and git (`rebase`, `commit --amend`, `push -f`, `push --force-with-lease`). The `immutable_heads()` revset already protects pushed jj commits — treat a "do you want to override?" moment as the same checkpoint: ask first.

## Background tasks

When a background task completes and sends a `<task-notification>` with an `<output-file>` path, read the file directly with the Read tool. Do NOT call `TaskOutput` — the task ID may already be cleaned up, causing a "No task found" error.
