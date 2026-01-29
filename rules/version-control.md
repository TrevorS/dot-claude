# Version Control

Use **jj (jujutsu)** for local work, **git** for GitHub interface. Load the `jj-workflow` skill for detailed commands and patterns.

- Check VCS: `jj root` — if it works, use jj; otherwise fall back to git
- IMPORTANT: Working copy should never be "(no description set)" — always `jj describe -m "..."` immediately

## Git (when not using jj)

- Temporary files: `/tmp/{repo-name}-{branch-name}-{temp-file-name}.txt`
- Use Write tool for commit messages (avoids shell escaping)
- Pre-commit hooks modify files during commit - this is normal, re-stage and retry
