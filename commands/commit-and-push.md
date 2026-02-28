# Commit and Push Changes

Validate, commit with a clear message, and push to remote. Monitor CI/CD in the background if configured.

## Steps

1. **Detect VCS** — `jj root` succeeds → jj workflow, otherwise git
2. **Check branch safety** — read `./CLAUDE.md` for branch protection and push policies; if on a protected branch without permission, suggest a feature branch
3. **Run validation** — auto-detect project type (`pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Makefile`) and run: format → lint → typecheck. Stop on failure.
4. **Craft commit message** — analyze diff and recent history for context
5. **Commit and push** — using the appropriate VCS
6. **Monitor CI/CD** — spawn background monitor if `.github/workflows/` exists

## jj Workflow

**CRITICAL:** Always pass `-m` to prevent jj from opening an editor.

**Pushed commits are immutable** — don't squash into them.

```bash
jj status && jj diff --stat

# Clean up empty checkpoint commits
jj log -r '::@' --no-graph
jj abandon <empty-checkpoint-ids>

# Describe and push
jj describe -m "feat: message here"
jj bookmark set <branch> -r @
jj git push --bookmark <branch>
```

If push is refused for a new bookmark:

```bash
jj config set --user 'remotes.origin.auto-track-bookmarks' 'glob:*'
```

On error: `jj op log` → `jj op restore` to undo.

## Git Workflow (fallback)

```bash
git status --short && git diff --stat
git add <specific-files>
git commit -F /tmp/commit-msg.txt
git push -u origin HEAD
```

Use the Write tool for commit message files (avoids shell escaping). Handle pre-commit hook failures by re-staging and retrying.

## CI/CD Monitoring

After a successful push, if `.github/workflows/` exists, run the ci-monitor script in the background:

```bash
uv run ~/.claude/skills/ci-monitor/ci-monitor.py --branch <branch-name>
```

Use `run_in_background: true`. The script handles dedup, polling, watching, and failure log fetching automatically.

Tell the user: "CI monitor running in background — you'll be notified when it completes."
