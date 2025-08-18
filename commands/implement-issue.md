# Implement Issue

<!-- ABOUTME: Creates feature branch and implements GitHub/Linear issues with TDD workflow -->

<!-- ABOUTME: Auto-detects issue system, creates PR, and follows comprehensive implementation standards -->

Issue: $ARGUMENTS

## Task

I'll **ultrathink** to develop a comprehensive solution for this issue with careful context management and optimal workflow execution.

I will:

1. **Auto-detect issue tracking system** - Check if GitHub (gh CLI) or Linear (linear-cli) based on argument format
2. **Check current git status** and ensure we're not working on main/master/dev
3. **Create feature branch** with proper naming convention based on issue details
4. **Read and understand issue requirements** using appropriate CLI tool
5. **Review project context** - check `spec.md`, `requirements.md`, `CLAUDE.md` for standards
6. **Follow TDD approach** - write comprehensive tests first
7. **Implement minimal code** to pass tests
8. **Refactor incrementally** while maintaining test coverage
9. **Document key architectural decisions** in code comments
10. **Push with upstream tracking** and create pull request
11. **Generate comprehensive PR description** with test plan
12. **Keep PR open** for review and iterate based on feedback

## Auto-Detection Logic

The command automatically detects the issue tracking system:

- **GitHub Issues**: Numeric (e.g., `42`, `#42`) or GitHub URL → Uses `gh` CLI
- **Linear Issues**: Team prefix format (e.g., `ENG-123`, `TEAM-456`) → Uses `linear-cli`
- **Manual Override**: Use `--github` or `--linear` flags to force specific system

## Branch Safety Protocol

**Pre-Implementation Checks:**

- Verify current branch with `git branch --show-current`
- If on protected branch (main/master/dev), create feature branch immediately
- Check for uncommitted changes and stash if necessary
- Fetch latest changes from origin

**Branch Naming Conventions:**

- **GitHub**: `feature/issue-{number}-{short-description}` or `fix/issue-{number}-{description}`
- **Linear**: `feature/{team-id}-{short-description}` or `fix/{team-id}-{description}`

## Pull Request Structure

### GitHub PRs

- **Title**: `[Issue #<number>] Short description of the change`
- **Body**: Detailed explanation with acceptance criteria checklist
- **Labels**: Auto-applied based on issue labels
- **Linked Issues**: `Closes #<number>` reference

### Linear PRs

- **Title**: `[TEAM-ID] Short description of the change`
- **Body**: Links to Linear issue and includes manual test plan
- **Teams**: Assigned based on Linear team configuration

## Command Reference

### GitHub Flow

```bash
# Check current branch
git branch --show-current

# View issue details with full context
gh issue view <number> --json title,body,labels,assignees,milestone

# Create feature branch
git checkout -b "feature/issue-<number>-<description>"

# Push with upstream tracking
git push -u origin HEAD

# Create PR linking to issue
gh pr create --title "[Issue #<number>] Title" --body "Closes #<number>"

# Search related issues
gh issue list --search "in:title <keyword>" --json number,title,labels
```

### Linear Flow

```bash
# View all issues
linear-cli issues

# View specific issue with details
linear-cli issue <team-id>

# Search issues by team or keyword
linear-cli issues --team <team-name>

# Create feature branch (manual naming)
git checkout -b "feature/<team-id>-<description>"
```

## Implementation Quality Standards

**Test-Driven Development:**

- Write failing tests first that capture acceptance criteria
- Implement minimal code to make tests pass
- Refactor while maintaining green tests

**Code Quality:**

- Follow project's established patterns from `CLAUDE.md`
- Add meaningful comments for complex logic
- Ensure all edge cases are tested
- Update documentation if public APIs change

**Branch Management:**

- Keep commits atomic and well-described
- Squash related commits before final push
- Include co-author attribution if pair programming
