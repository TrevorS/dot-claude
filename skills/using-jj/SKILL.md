---
name: using-jj
description: Jujutsu (jj) version control reference. MUST load this skill whenever a query mentions jj, jujutsu, revsets, bookmarks, absorb, evolog, oplog, immutable_heads, divergent changes, or jj-specific concepts — jj differs from git in non-obvious ways and the skill contains critical constraints (e.g., always pass -m, the exact non-interactive form of split, which revision a bookmark must target before pushing) that prevent broken workflows. Skip only for trivial jj commands you're certain about (describe, new, commit, push).
when_to_use: "Typed as 'how do I X in jj', or any question about squash, rebase, split, absorb, evolog, oplog, bookmarks, or conflicts — especially where a git habit would produce a wrong or editor-blocking jj command."
---

# jj Workflow

For daily-command tables, git equivalents, troubleshooting, parallel-experiment patterns, immutable-heads disable/restore commands, recommended config, and the full revset cheatsheet, see `REFERENCE.md`.

## Philosophy

1. **Commits are cheap, descriptions are mandatory.** The working copy is always a commit. Never leave it as "(no description set)".
2. **Experiment freely, the oplog is your safety net.** `jj undo` and `jj op restore` make anything reversible.
3. **Conflicts are state, not emergencies.** jj records conflicts in commits as structured data; rebase still succeeds.
4. **Change IDs are your handle on work.** Commit hashes change on rewrite; change IDs don't.
5. **Bookmarks exist for GitHub, not for you.** Work with anonymous changes; add bookmarks only when pushing.
6. **Keep the stack shallow.** Squash early.
7. **Use `absorb` over manual squash routing.** Let jj distribute hunks to the right ancestor.
8. **Colocated = invisible to the team.** Teammates see standard git.

## CRITICAL: AI-specific rules

The full editor-hazard table (every command that opens an editor, and its safe form)
is in the always-loaded `rules/version-control.md` — not repeated here. The one-line
version: **always pass `-m`**, never pass `-i`/`--interactive`/`--tool`, and never
reach for `jj diffedit` or `jj resolve` without `--tool`.

`jj split` is the exception worth knowing: it has a non-interactive form (verified
against jj 0.44), but it needs **both** paths and `-m`:

```bash
jj split -r <rev> -m "first part" path/a path/b   # rest stays in the child commit
```

Without filesets `-i` is the default (diff editor); without `-m` the description editor
opens; `--editor` forces one even with `-m`. `hooks/jj_interactive_guard.sh` allows only
the safe shape, so a wrong form blocks instantly instead of hanging. This is the clean
way to break one change into several commits — no restore/copy dance needed.

Two guards enforce it: `hooks/jj_interactive_guard.sh` blocks editor-opening
invocations pre-run, and `$JJ_EDITOR` (`hooks/jj-reject-editor.sh`) fail-fasts any
editor jj still opens.

## Core concepts

- Working copy = commit. Every file edit is tracked in `@`. No staging area, no `git add`.
- `@` = current change, `@-` = parent, `@--` = grandparent.
- Change IDs (e.g. `kpqxywon`) are stable across rewrites. Use these, not commit hashes.
- Conflicts are state, not emergencies — jj records them in commits and rebase still succeeds.
- Previous versions: `<change-id>/0` (latest), `/1` (previous). `jj restore --from xyz/1 --to xyz` reverts to a prior state.

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

If a PR has review comments, do NOT squash or rewrite the original commits — review threads detach from line anchors. Add new commits on top instead, and only rewrite after Teej confirms. See `rules/version-control.md`.

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
