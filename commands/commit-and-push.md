# Commit and Push Changes

<!-- ABOUTME: Auto-stages, validates, commits with clear message, and pushes changes to remote -->

<!-- ABOUTME: Handles branch safety, validation pipeline, and upstream tracking automatically -->

Auto-stage, validate, commit with a clear message, and push changes to the remote repository.

## Task

I'll figure out the best validation, commit, and push workflow for this project.

I will:

1. **Check project permissions** in `./CLAUDE.md` for branch protection and push policies
2. **Run full validation** - auto-detect and execute formatters, linters, type checkers
3. **Write clear commit message** using git history and staged change analysis
4. **Handle branch safety** - verify not pushing directly to protected branches inappropriately
5. **Auto-stage, commit, and push** with upstream tracking and proper error handling

## Branch Safety Protocol

Check `./CLAUDE.md` for project permissions. If on protected branch without permission, suggest feature branch. Cache decisions for future runs.

## Safety Checks

- Check branch protection via CLAUDE.md
- Verify push permissions
- Run code quality validation
- Handle pre-commit hooks and conflicts
- Stop on validation failures

## Commands Used

```bash
grep "## Project Permissions" ./CLAUDE.md
git branch --show-current
git add . && git commit -F /tmp/commit-msg.txt
git push -u origin HEAD
```

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Handle push permission denials gracefully
- Auto-fix code quality issues using detected formatters/linters
- Re-stage once if pre-commit hooks fail
- Provide clear guidance for manual fixes when auto-fix isn't possible

## Modern Validation and Git Flow

- **Auto-detect project type**: Scan for `pyproject.toml`, `package.json`, `Cargo.toml`, `Makefile`
- **Run validation pipeline**: Execute format → lint → typecheck → test based on detected tools
- **Write commit messages**: Look at staged changes and recent commit history for context
- **Handle upstream tracking**: Set up remote tracking automatically for new branches
- **Cache project information**: Update CLAUDE.md with validation tools and branch policies

Example CLAUDE.md section:

```markdown
## Project Permissions

- **Project Type**: personal|work
- **Direct Commits Allowed**: yes|no
- **Push to Main Allowed**: yes|no
- **Last Checked**: 2024-08-09
```
