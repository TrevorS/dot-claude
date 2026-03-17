# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface.

**AUTO-LOAD**: When the hook output contains `vcs=jj-colocated` or `vcs=jj`, ALWAYS load the `using-jj` skill before doing any version control work. This is not optional. When hook output contains `vcs=git` (not jj), load the `using-git` skill.

## Quick Reference (details in skills)

- **jj**: Always use `-m` flag. Working copy should never be "(no description set)".
- **git**: Use Write tool for commit messages (avoids shell escaping). Pre-commit hooks modify files during commit — re-stage and retry.
