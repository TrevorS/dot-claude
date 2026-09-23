# Version Control

Use **jj (jujutsu)** for local work, **git** for the GitHub interface. Load the `using-jj` skill for anything past the basics (revsets, absorb, oplog recovery, conflicts, the split form).

## jj

- Pass `-m` to `describe`, `commit`, `new`, `squash`; a hook blocks the editor-opening forms.
- Use change IDs (`kpqxywon`), not commit hashes; they survive rewrites.
- Conflicts are state, not emergencies: jj records them in commits and rebase still succeeds.

## git

- Long commit messages go in a scratchpad file (`-F`), not inline quoting. The built-in `/commit` refuses `-F`; use its heredoc form there.
- Pre-commit hooks modify files during commit; re-stage and retry.
