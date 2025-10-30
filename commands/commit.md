# Commit Changes

<!-- ABOUTME: Auto-stages, validates, commits, and optionally pushes changes with clear messages -->

<!-- ABOUTME: Unified commit workflow supporting both local commits and push with branch safety -->

Auto-stage, validate, and commit changes with a clear message. Optional push to remote.

Usage: `/commit [--push] [--validate]`

## Task

I'll figure out the best validation and commit approach for this project.

I will:

1. **Check project permissions** in `./CLAUDE.md` for branch protection and validation requirements
2. **Run project validation** (if `--validate` flag) - auto-detect and execute formatters, linters, type checkers
3. **Write clear commit message** using git history and change analysis
4. **Handle branch safety** - verify not committing directly to protected branches
5. **Auto-stage and commit** changes with proper error handling
6. **Push to remote** (if `--push` flag) with upstream tracking and safety checks

## Flags

- `--validate`: Run validation (format, lint, typecheck) before committing (default: true)
- `--push`: Push to remote after commit with upstream tracking (default: false)
- `--no-validate`: Skip validation and commit directly (use with caution)

## Branch Safety Protocol

Check `./CLAUDE.md` for project permissions. If on protected branch without permission, suggest feature branch. Cache decisions for future runs.

## Safety Checks

- Check branch protection via CLAUDE.md
- Verify push permissions (if `--push`)
- Run code quality validation (if `--validate`)
- Handle pre-commit hooks and conflicts
- Stop on validation failures (unless `--no-validate`)

## CLI References

**Git Operations**: See `@git-workflows` skill for:

- Staging changes (`git add`)
- Creating commits (`git commit`)
- Pushing to remote (`git push -u origin HEAD`)
- Viewing commit history (`git log`)

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Auto-fix code quality issues using detected formatters/linters
- Re-stage once if pre-commit hooks fail
- Provide clear guidance for manual fixes when auto-fix isn't possible

## Modern Validation Flow

- **Auto-detect project type**: Scan for `pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`
- **Run validation pipeline**: Execute format → lint → typecheck → test based on detected tools
- **Write commit messages**: Look at staged changes and recent commit history for context
- **Cache project information**: Update CLAUDE.md with validation tools and branch policies

Example CLAUDE.md section:

```markdown
## Project Permissions

- **Project Type**: personal|work
- **Direct Commits Allowed**: yes|no
- **Push to Main Allowed**: yes|no
- **Last Checked**: 2024-08-09
```

## Examples

```bash
# Commit with validation (default)
/commit

# Commit and push to remote
/commit --push

# Commit without validation
/commit --no-validate

# Commit and push without running validation
/commit --push --no-validate
```
