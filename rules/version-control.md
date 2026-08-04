# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface. Load `using-jj` skill for advanced jj workflows (revsets, absorb, oplog recovery, conflict resolution).

## Non-interactive jj (critical)

Always pass `-m` — unset opens an editor and blocks the agent:

```bash
jj new -m "msg"
jj describe -m "msg"
jj commit -m "msg"
jj squash -m "msg"   # or -u to reuse the destination commit's message
```

**Every command that opens an editor and hangs (verified against jj 0.44) — use the safe form:**

| Command | Opens an editor when… | Safe form |
| --- | --- | --- |
| `jj describe` | no message | add `-m "msg"` or `--stdin` |
| `jj commit` | no message | add `-m "msg"` — **`jj commit` has no `--stdin`**; for a long message use `jj describe --stdin` then `jj new -m` |
| `jj squash` | combining descriptions | add `-m "msg"`, or `-u` to reuse the destination's |
| `jj commit` / `jj squash` `-i`/`--interactive`/`--tool` | always (diff editor for hunks; `--tool` implies `-i`) | drop the flag — edit files, then `jj squash -m` |
| `jj split` | only when **no filesets** are given (`-i` is the default in that case) | pass paths: `jj split -r <rev> -m "msg" <paths>` is non-interactive |
| `jj diffedit` | always | no non-interactive mode — restructure with `jj squash -m` / `jj new -m` |
| `jj resolve` | always (merge editor) | edit the conflict markers in the files, then `jj squash -m`; or pass `--tool` |
| `jj config edit` | always | `jj config set <name> <value>` (`--user`/`--repo` for scope) |

**Caveat on `jj split`:** the fileset form is safe in jj 0.43, but
`hooks/jj_interactive_guard.sh` still blocks every `jj split` unconditionally.
Until that hook is taught the fileset exception, split a change by restoring the
other groups' files from the parent (`jj restore --from @- <paths>`), committing,
then writing them back.

**To untrack a file** use `jj file untrack <path>` — `jj forget` does **not** exist in this jj version.

**Tell for "an editor tried to open":** if a mutating jj command *auto-backgrounds* or seems to vanish, it's blocking on an editor, not a mystery — re-run it with `-m`. Two guards enforce this so a hang becomes a fast error instead:

- `jj_interactive_guard.sh` (PreToolUse hook) blocks editor-opening invocations *before* they run, with the exact fix.
- `$JJ_EDITOR` → `hooks/jj-reject-editor.sh` fail-fasts any editor jj still tries to open (exit 1, instant), so it never hangs. This is scoped to Claude Code's env only; your interactive `nvim` editor is unaffected.

## Core concepts

- Working copy = commit. Every file edit is tracked in `@`. No staging area, no `git add`.
- `@` = current change, `@-` = parent, `@--` = grandparent.
- Change IDs (e.g. `kpqxywon`) are stable across rewrites. Use these, not commit hashes.
- Conflicts are state, not emergencies — jj records them in commits and rebase still succeeds.

## git essentials

- Use Write tool for commit messages (avoids shell escaping issues).
- Pre-commit hooks modify files during commit — re-stage and retry.
- `git reset --soft HEAD~N` to squash N commits non-interactively.
- Never use `git rebase -i` or `git add -i` — interactive modes block the agent.
- Never rebase shared branches.
- Before destructive ops (reset --hard, force push), create a backup: `git branch backup-$(date +%s)`.

See `pr-safety.md` for rules on rewriting history of branches that already have a PR open.
