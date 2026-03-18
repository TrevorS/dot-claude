# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface.

For advanced workflows (revsets, absorb, oplog recovery, conflict resolution), load the `using-jj` or `using-git` skill.

## jj Essentials

### Non-Interactive Commands (CRITICAL)

Always use `-m` flag to prevent jj from opening an editor:

```bash
# CORRECT
jj new -m "message"
jj describe -m "message"
jj commit -m "message"
jj squash -m "message"

# WRONG - opens editor, blocks AI
jj new
jj describe
jj commit
jj squash
```

Never use these interactive commands (no non-interactive mode):

- `jj split` / `jj split -i`
- `jj squash -i`
- `jj diffedit`

### Core Concepts

- **Working copy = commit.** Every file edit is tracked in `@` (current change). No staging area, no `git add`.
- `@` = current change, `@-` = parent, `@--` = grandparent
- **Change IDs** (e.g., `kpqxywon`) are stable across rewrites. Use these, not commit hashes.
- **Conflicts are state, not emergencies.** jj records conflicts in commits. Rebase succeeds even with conflicts.
- Working copy should never be "(no description set)".

### Workflows

**Commit workflow** (simplest):

```bash
# ... make changes ...
jj commit -m "feat: what I did"    # describe + create new change
```

**Squash workflow** (recommended for stacking):

```bash
jj describe -m "feat: what I'm building"
jj new -m "wip"
# ... make changes ...
jj squash -m "feat: done"          # squash into parent
```

**Mid-stack fix**:

```bash
jj edit <change-id>                # switch to that change
# ... fix ...
jj new -m "back to work"           # descendants auto-rebased
```

### Bookmarks & Pushing

Bookmarks don't auto-advance. Move them explicitly:

```bash
jj bookmark set master -r @-       # point at commit, not empty @
jj git push

jj bookmark create feature-x -r @-  # new feature branch
jj git push

jj bookmark set feature-x -r @-     # update after more work
jj git push
```

### Syncing

```bash
jj git fetch
jj rebase -d master@origin
```

## git Essentials

- Use Write tool for commit messages (avoids shell escaping issues)
- Pre-commit hooks modify files during commit — re-stage and retry
- `git reset --soft HEAD~N` to squash N commits
- Never rebase shared branches
