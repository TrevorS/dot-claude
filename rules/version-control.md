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
