# Commit Changes

<!-- ABOUTME: Auto-stages, validates, and commits changes with clear messages -->

<!-- ABOUTME: Supports incremental development workflow without pushing to remote -->

Auto-stage, validate, and commit changes with a clear message for incremental development workflow.

## Task

I'll figure out the best validation and commit approach for this project.

I will:

1. **Detect VCS** - Check if this is a jj repo (preferred) or git-only repo
2. **Clean up checkpoints** - Abandon/squash any "checkpoint:" commits from Claude's Stop hook
3. **Check project permissions** in `./CLAUDE.md` for branch protection and validation requirements
4. **Run project validation** - auto-detect and execute formatters, linters, type checkers
5. **Write clear commit message** using history and change analysis
6. **Handle branch safety** - verify not committing directly to protected branches
7. **Commit** changes with proper error handling (no push)

## VCS Detection (Do This First)

```bash
# Check if jj repo exists
if jj root 2>/dev/null; then
  # USE JJ WORKFLOW
else
  # USE GIT WORKFLOW
fi
```

## jj Checkpoint Cleanup

Claude's Stop hook creates "checkpoint: YYYY-MM-DD_HH:MM:SS" commits automatically. Clean these up before committing:

```bash
# Check for checkpoint commits
jj log --no-graph -r '::@' -T 'if(description.starts_with("checkpoint:"), change_id ++ "\n")' | head -5

# If checkpoints exist and are empty, abandon them
jj abandon <checkpoint-change-ids>

# Or if they have changes, squash into parent
jj squash -r <checkpoint-change-id>
```

**CRITICAL: Always use `-m` flag with jj** to prevent editor from blocking:

- `jj describe -m "message"` (not `jj describe`)
- `jj new -m "message"` (not `jj new`)

## Branch Safety Protocol

Check `./CLAUDE.md` for project permissions. If on protected branch without permission, suggest feature branch. Cache decisions for future runs.

## Safety Checks

- Check branch protection via CLAUDE.md
- Run code quality validation
- Handle pre-commit hooks and conflicts
- Stop on validation failures

## Commands Used

```bash
# Check permissions
grep "## Project Permissions" ./CLAUDE.md

# jj workflow (preferred)
jj root && jj status && jj diff
jj describe -m "commit message"

# git workflow (fallback)
git branch --show-current
git add . && git commit -F /tmp/commit-msg.txt
```

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Auto-fix code quality issues using detected formatters/linters
- Re-stage once if pre-commit hooks fail (git only)
- For jj: use `jj op restore` if something goes wrong
- Provide clear guidance for manual fixes when auto-fix isn't possible

## Modern Validation Flow

- **Auto-detect project type**: Scan for `pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`
- **Run validation commands**: Execute format → lint → typecheck → test based on detected tools
- **Write commit messages**: Look at staged changes and recent commit history for context
- **Cache project information**: Update CLAUDE.md with validation tools and branch policies

Example CLAUDE.md section:

```markdown
## Project Permissions

- **Project Type**: personal|work
- **Direct Commits Allowed**: yes|no
- **Last Checked**: 2024-08-09
```
