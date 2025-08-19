# Commit Changes

<!-- ABOUTME: Auto-stages, validates, and commits changes with clear messages -->

<!-- ABOUTME: Supports incremental development workflow without pushing to remote -->

Auto-stage, validate, and commit changes with a clear message for incremental development workflow.

## Task

I'll figure out the best validation and commit approach for this project.

I will:

1. **Check project permissions** in `./CLAUDE.md` for branch protection and validation requirements
2. **Run project validation** - auto-detect and execute formatters, linters, type checkers
3. **Write clear commit message** using git history and change analysis
4. **Handle branch safety** - verify not committing directly to protected branches
5. **Auto-stage and commit** changes with proper error handling

## Branch Safety Protocol

Check `./CLAUDE.md` for project permissions. If on protected branch without permission, suggest feature branch. Cache decisions for future runs.

## Safety Checks

- Check branch protection via CLAUDE.md
- Run code quality validation
- Handle pre-commit hooks and conflicts
- Stop on validation failures

## Commands Used

```bash
grep "## Project Permissions" ./CLAUDE.md
git branch --show-current
git add . && git commit -F /tmp/commit-msg.txt
```

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Auto-fix code quality issues using detected formatters/linters
- Re-stage once if pre-commit hooks fail
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
