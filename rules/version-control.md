# Version Control

Use **jj (jujutsu)** for local work, **git** for the GitHub interface. Load the `using-jj` skill for anything past the basics (revsets, absorb, oplog recovery, conflicts, the split form).

## jj

- Always pass `-m` to `describe`, `commit`, `new`, `squash`. Without it jj opens an editor and the session blocks. Two hooks (`jj_interactive_guard.sh`, `$JJ_EDITOR` reject) catch the editor-opening forms and print the fix; if a mutating jj command seems to vanish, that is what happened. Re-run with `-m`.
- Use change IDs (`kpqxywon`), not commit hashes; they survive rewrites.
- To untrack a file use `jj file untrack <path>`. `jj forget` does not exist in this jj version.
- Conflicts are state, not emergencies: jj records them in commits and rebase still succeeds.

## git

- Long commit messages go in a scratchpad file (`-F`), not inline quoting.
- Pre-commit hooks modify files during commit; re-stage and retry.
- Rewriting history on a branch with an open PR is governed by `pr-safety.md`.
