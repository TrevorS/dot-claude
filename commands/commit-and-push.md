# Commit and Push Changes

<!-- ABOUTME: Auto-stages, validates, commits with clear message, and pushes changes to remote -->

<!-- ABOUTME: Handles jj/git detection, branch safety, validation pipeline, and upstream tracking -->

Auto-stage, validate, commit with a clear message, and push changes to the remote repository.

## Task

I'll figure out the best validation, commit, and push workflow for this project.

I will:

1. **Detect VCS** - Check if this is a jj repo (preferred) or git-only repo
2. **Check project permissions** in `./CLAUDE.md` for branch protection and push policies
3. **Run full validation** - auto-detect and execute formatters, linters, type checkers
4. **Write clear commit message** using history and change analysis
5. **Handle branch safety** - verify not pushing directly to protected branches inappropriately
6. **Commit and push** using the appropriate VCS tool

## VCS Detection (CRITICAL - Do This First)

```bash
# Check if jj repo exists
if jj root 2>/dev/null; then
  # USE JJ WORKFLOW
else
  # USE GIT WORKFLOW
fi
```

**Always prefer jj when available** - it has better undo, cleaner history curation, and atomic operations.

## jj Workflow (When .jj/ exists)

**CRITICAL: Always use `-m` flag** to prevent jj from opening an editor (blocks AI):

### Step 1: Detect and Clean Up Checkpoint Commits

Claude's Stop hook creates "checkpoint: YYYY-MM-DD_HH:MM:SS" commits automatically. These must be cleaned up before pushing.

```bash
# Check for checkpoint commits (empty commits with "checkpoint:" prefix)
jj log --no-graph -r '::@' -T 'if(description.starts_with("checkpoint:"), change_id ++ "\n")' | head -5

# If checkpoints exist, abandon them (they're typically empty)
jj abandon <checkpoint-change-ids>

# Or if they have actual changes, squash into parent:
jj squash -r <checkpoint-change-id>
```

### Step 2: Normal Commit Flow

```bash
# 1. Check status and changes
jj status
jj diff

# 2. View commits to squash (commits on top of main)
jj log -r 'main..@'

# 3. If main is immutable (already pushed), create new commit on main:
jj new main -m "commit message here"
jj restore --from <change-id-with-work> .   # Bring in changes
jj bookmark set main -r @
jj git push

# 4. If main is mutable, squash into it:
jj squash --into main -m "commit message here"
jj bookmark set main -r @
jj git push

# 5. Track remote bookmark if needed
jj bookmark track main@origin
```

**NEVER use without `-m` flag:**

- `jj new` → use `jj new -m "message"`
- `jj describe` → use `jj describe -m "message"`
- `jj squash` → use `jj squash -m "message"`

**jj advantages:**

- `jj op log` + `jj op restore` for easy undo
- No staging area complexity
- Atomic squash operations
- Clean checkpoint → final commit workflow

## Git Workflow (Fallback when no jj)

```bash
# 1. Check status
git status --short
git diff --stat

# 2. Stage and commit
git add .
git commit -F /tmp/commit-msg.txt

# 3. Push with upstream tracking
git push -u origin HEAD
```

## Branch Safety Protocol

Check `./CLAUDE.md` for project permissions. If on protected branch without permission, suggest feature branch.

## Safety Checks

- Check branch protection via CLAUDE.md
- Verify push permissions
- Run code quality validation
- Handle pre-commit hooks and conflicts
- Stop on validation failures

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Handle push permission denials gracefully
- Auto-fix code quality issues using detected formatters/linters
- For jj: use `jj op restore` if something goes wrong
- Provide clear guidance for manual fixes when auto-fix isn't possible

## Validation Pipeline

- **Auto-detect project type**: Scan for `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Makefile`
- **Run validation**: Execute format → lint → typecheck → test based on detected tools
- **Write commit messages**: Look at changes and recent history for context

## Example CLAUDE.md Section

```markdown
## Project Permissions

- **Project Type**: personal|work
- **Direct Commits Allowed**: yes|no
- **Push to Main Allowed**: yes|no
- **Last Checked**: 2024-08-09
```
