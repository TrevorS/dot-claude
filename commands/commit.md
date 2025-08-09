# Commit Changes

Auto-stage, validate, and commit changes with a clear message for incremental development workflow.

## Task

I will:

1. Check project permissions in `./CLAUDE.md`
2. Use project-validator agent for code quality
3. Use git-message-crafter agent for commit message and branch safety
4. Auto-stage files and commit changes (no push)

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
- Use agents to fix code quality issues
- Re-stage once if pre-commit hooks fail

## Agent Integration

- **project-validator agent**: Runs formatters, linters, type checkers
- **git-message-crafter agent**: Handles branch safety and commit messages
- Caches project permissions in CLAUDE.md for future runs

Example CLAUDE.md section:

```markdown
## Project Permissions

- **Project Type**: personal|work
- **Direct Commits Allowed**: yes|no
- **Last Checked**: 2024-08-09
```
