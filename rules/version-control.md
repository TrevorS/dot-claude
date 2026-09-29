# Version Control

Use **jj (jujutsu)** for local work, **git** for the GitHub interface.

## jj

- Pass `-m` to `describe` and `commit`. For `squash --into`, pass `-u` to keep the destination's message or `-m` to replace it. A hook blocks the forms that open an editor.
- Use change IDs (`kpqxywon`), not commit hashes; they survive rewrites.
- Conflicts are state, not emergencies: jj records them in commits and rebase still succeeds.

## git

- Long commit messages go in a scratchpad file (`-F`), not inline quoting. The built-in `/commit` refuses `-F`; use its heredoc form there.
- Pre-commit hooks modify files during commit; re-stage and retry.
