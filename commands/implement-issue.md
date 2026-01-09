# Implement Issue

<!-- ABOUTME: Creates feature branch and implements GitHub/Linear issues with TDD workflow -->

<!-- ABOUTME: Auto-detects issue system and VCS (jj/git), creates PR, follows good implementation standards -->

Issue: $ARGUMENTS

## Task

I'll work through this issue carefully and figure out the best workflow.

I will:

1. **Auto-detect version control** - Check if repo uses jj (`jj root`) or plain git
2. **Auto-detect issue tracking system** - Check if GitHub (gh CLI) or Linear (linear-cli) based on argument format
3. **Check current working copy status** and ensure we're not on main/master/dev
4. **Create feature branch** with proper naming convention based on issue details
5. **Read and understand issue requirements** using appropriate CLI tool
6. **Review project context** - check `spec.md`, `requirements.md`, `CLAUDE.md` for standards
7. **Follow TDD approach** - write complete tests first
8. **Implement minimal code** to pass tests
9. **Refactor incrementally** while maintaining test coverage
10. **Document key architectural decisions** in code comments
11. **Clean up history** - squash/curate commits before pushing
12. **Push with upstream tracking** and create pull request
13. **Write complete PR description** with test plan
14. **Keep PR open** for review and iterate based on feedback

## Auto-Detection Logic

The command automatically detects the issue tracking system:

- **GitHub Issues**: Numeric (e.g., `42`, `#42`) or GitHub URL → Uses `gh` CLI
- **Linear Issues**: Team prefix format (e.g., `ENG-123`, `TEAM-456`) → Uses `linear-cli`
- **Manual Override**: Use `--github` or `--linear` flags to force specific system

## VCS Detection

**Check which version control system to use:**

```bash
jj root  # If this succeeds, use jj. If not, fall back to git.
```

## Branch Safety Protocol

**Pre-Implementation Checks (jj):**

- Check current bookmark: `jj log -r @ --no-graph -T 'bookmarks'`
- If on main/master, create new change: `jj new main -m "feat: description"`
- No need to stash - jj auto-tracks all changes
- Fetch latest: `jj git fetch`

**Pre-Implementation Checks (git):**

- Verify current branch with `git branch --show-current`
- If on protected branch (main/master/dev), create feature branch immediately
- Check for uncommitted changes and stash if necessary
- Fetch latest changes from origin

**Branch/Bookmark Naming Conventions:**

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

### jj Flow (preferred when available)

```bash
# Check if jj is available
jj root

# Check current position
jj log -r @ --no-graph

# Start new work from main
jj new main -m "feat: issue-<number> short description"

# Create bookmark for pushing
jj bookmark create "feature/issue-<number>-<description>"

# During implementation - jj auto-tracks, use checkpoints for risky changes
jj new -m "checkpoint: trying new approach"

# Annotate current work
jj describe -m "feat: updated description of what this does"

# Before pushing - clean up history
jj squash  # Combine working changes into parent

# Push to remote (first time)
jj git push --allow-new

# Push updates
jj git push

# Undo mistakes
jj op log                    # Find operation to restore
jj op restore <operation-id> # Restore to that point
jj restore --from @- <path>  # Surgical undo of specific files
```

### GitHub Flow (git)

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

### Linear Flow (git)

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

### Linear Flow (jj)

```bash
# View issue details
linear-cli issue <team-id>

# Start new work
jj new main -m "feat: <team-id> short description"
jj bookmark create "feature/<team-id>-<description>"

# Push when ready
jj squash
jj git push --allow-new
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

**Branch Management (jj):**

- Use `jj new -m "checkpoint"` before risky experiments
- Use `jj describe` to update commit messages as understanding evolves
- Use `jj squash` to combine checkpoints into clean commits before push
- Teammates see clean git history - they can't tell you used jj

**Branch Management (git):**

- Keep commits atomic and well-described
- Squash related commits before final push
- Include co-author attribution if pair programming
