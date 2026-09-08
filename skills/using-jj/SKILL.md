---
name: using-jj
description: Jujutsu (jj) reference for anything past describe/new/commit/push -- the non-interactive split form, which revision a bookmark must target before pushing, absorb, evolog, oplog recovery, immutable heads, revsets. Load whenever a git habit could produce a wrong or editor-blocking jj command.
when_to_use: "Typed as 'how do I X in jj', or any question about squash, rebase, split, absorb, evolog, oplog, bookmarks, or conflicts — especially where a git habit would produce a wrong or editor-blocking jj command."
---

# jj Workflow

For daily-command tables, git equivalents, troubleshooting, parallel-experiment patterns, immutable-heads disable/restore commands, recommended config, and the full revset cheatsheet, see `REFERENCE.md`.

## House style

1. **Descriptions are mandatory.** Never leave the working copy as "(no description set)".
2. **Change IDs are your handle on work.** Commit hashes change on rewrite; change IDs don't.
3. **Bookmarks exist for GitHub, not for you.** Work with anonymous changes; add bookmarks only when pushing.
4. **Use `absorb` over manual squash routing.** Let jj distribute hunks to the right ancestor.

## Editor-opening commands

Always pass `-m`; never pass `-i`/`--interactive`/`--tool`; never reach for `jj diffedit`
or `jj resolve` without `--tool` (`rules/version-control.md`; the hooks block the rest
and print the fix).

`jj split` has a non-interactive form (verified against jj 0.44) that needs **both**
paths and `-m`; without filesets `-i` is the default, without `-m` the description
editor opens, and `--editor` forces one even with `-m`:

```bash
jj split -r <rev> -m "first part" path/a path/b   # rest stays in the child commit
```

## Evolog addressing

Previous versions: `<change-id>/0` (latest), `/1` (previous). `jj restore --from xyz/1 --to xyz` reverts to a prior state.

## Workflows

### Squash (recommended)

```bash
jj describe -m "feat: what I'm building"
jj new -m "wip"
# ... make changes ...
jj squash -m "feat: done"
```

### Commit (simpler)

```bash
jj commit -m "feat: what I did"   # = describe + new
```

### Edit (mid-stack fix)

```bash
jj edit <change-id>
# ... fix ...
jj new -m "back to work"   # descendants auto-rebased
```

## Absorb

From `@`, `jj absorb` routes each hunk to the ancestor where those lines were last modified. Use instead of manual squash routing when fixing across a stack.

## Bookmarks & pushing

Bookmarks don't auto-advance — move them explicitly. **Target whichever revision
actually holds the work**, which depends on the flow you just used:

```bash
jj bookmark set <name> -r @-    # after `jj squash`/`jj commit`: @ is a fresh empty change
jj bookmark set <name> -r @     # after `jj describe -m` alone: @ IS the work
jj git push
```

Getting this wrong is silent: pushing `@-` when `@` holds the work publishes the
previous commit, and CI then reports a green result for code you never pushed.
Check with `jj log -r @` before setting the bookmark if you're unsure.

## Don't rewrite reviewed PR history

Governed by `rules/pr-safety.md`: review activity on the PR means new commits on top, not a rewrite, until Teej confirms.

Default (safe — preserves comment anchors):

```bash
jj new feature-x -m "fixup: address feedback"
# ... make changes ...
jj bookmark set feature-x -r @
jj git push
```

`jj new feature-x` (no trailing `-`) stacks the fix **on top of** the bookmark.
`feature-x-` is the revset for *parents of* `feature-x`, so it would branch a
sibling off the reviewed commit and `bookmark set -r @-` would then drag the
bookmark backwards, dropping the very commit the reviewers annotated.

## Creating PRs (jj + gh)

In jj-colocated repos, git HEAD is detached — `gh pr create` fails with "not on any branch". **Always pass `--head <bookmark>`** — never rely on git auto-detection:

```bash
jj bookmark set feature-x -r @-   # or -r @ — see "Bookmarks & pushing" above
jj git push
gh pr create --head feature-x --title "..." --body "..."
```

## Recovery

```bash
jj op log
jj undo
jj op restore <id>
jj evolog [-r <change-id>]
```

## Immutable commits

Pushed commits are protected by `immutable_heads()`. **Always ask Teej before disabling protection** — rewriting remote bookmarks means force-pushing shared history. See `REFERENCE.md` for the disable/restore commands.

## Revsets

```bash
jj log -r 'trunk()..@'              # everything between main and here
jj log -r '::@ & ~::trunk()'         # my branch only
jj log -r 'author("trevor")'         # my commits
```

Full cheatsheet in `REFERENCE.md`.
