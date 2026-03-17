# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface.

**AUTO-LOAD**: When the hook output contains `vcs=jj-colocated` or `vcs=jj`, ALWAYS load the `using-jj` skill before doing any version control work. This is not optional.

## jj Principles (always apply when vcs=jj)

- Working copy should never be "(no description set)" — always `jj describe -m "..."` immediately
- Always use `-m` flag on jj commands to avoid opening an editor
- Conflicts are state, not emergencies — resolve when convenient
- Use change IDs (not commit hashes) to refer to work
- Bookmarks exist for GitHub push, not for local work
- The oplog is your safety net — experiment freely

## Git (when not using jj)

**AUTO-LOAD**: When the hook output contains `vcs=git` (not jj), load the `using-git` skill for squash and rebase patterns.

- Temporary files: `/tmp/{repo-name}-{branch-name}-{temp-file-name}.txt`
- Use Write tool for commit messages (avoids shell escaping)
- Pre-commit hooks modify files during commit - this is normal, re-stage and retry
