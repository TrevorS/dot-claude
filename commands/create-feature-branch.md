# Create Feature Branch

<!-- ABOUTME: Creates properly named feature branches with GitHub issue integration -->

<!-- ABOUTME: Auto-detects branch type and follows conventional naming patterns -->

Create a properly named feature branch from the current state, with optional GitHub issue integration.

Usage: `/create-feature-branch [description-or-issue-number]`

## Task

I'll create a feature branch following git best practices and naming conventions.

I will:

1. **Check current git status** and ensure clean working directory
2. **Determine branch type** (feature, fix, chore) based on description or issue
3. **Generate proper branch name** following conventional naming patterns
4. **Create and switch to new branch** from current HEAD
5. **Set up upstream tracking** if pushing is needed
6. **Confirm successful branch creation** and provide next steps

## Branch Naming Convention

### Automatic Detection

- **Issue numbers** (e.g., `42`, `#42`) → `feature/issue-42-description` or `fix/issue-42-description`
- **Bug keywords** (e.g., "fix", "bug") → `fix/description`
- **Feature keywords** (e.g., "add", "implement") → `feature/description`
- **Maintenance** (e.g., "refactor", "update") → `chore/description`

### Format Examples

```text
feature/user-authentication
fix/login-validation-error
fix/issue-42-password-reset
feature/issue-15-dashboard-widgets
chore/update-dependencies
```

## Command Reference

```bash
# Check current status
git status --porcelain

# Get current branch
git branch --show-current

# Fetch latest (if needed)
git fetch origin

# View issue details
gh issue view <number> --json title,labels

# Create feature branch
git checkout -b "feature/description"

# Create fix branch
git checkout -b "fix/description"

# Create issue-based branch
git checkout -b "feature/issue-<number>-description"
```

## GitHub Issue Integration

When providing an issue number:

- Fetches issue title and labels from GitHub
- Automatically determines if it's a `fix/` or `feature/` based on labels
- Includes issue number in branch name for traceability
- Handles both `42` and `#42` formats

## Safety Features

- **Clean Working Directory**: Warns if there are uncommitted changes
- **Current Branch Context**: Shows what branch the new branch is created from
- **Duplicate Protection**: Checks if branch name already exists locally
- **Remote Awareness**: Fetches latest changes before branch creation

## Next Steps Guidance

After branch creation:

- Suggests running `/implement-issue <number>` for issue-based work
- Recommends `/commit-and-push` when ready to share work
- Provides quick reference for switching back to previous branch
