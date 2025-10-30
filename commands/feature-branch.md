# Feature Branch Management

<!-- ABOUTME: Create and manage feature branches with GitHub issue integration and change preservation -->

<!-- ABOUTME: Unified workflow for creating new branches and moving work from protected branches -->

Create or switch to feature branches with proper naming conventions and change preservation.

Usage: `/feature-branch create [description-or-issue-number]` or `/feature-branch switch [branch-name-or-description]`

## Create a Feature Branch

Create a properly named feature branch from the current state, with optional GitHub issue integration.

### Task (Create)

I'll create a feature branch following git best practices and naming conventions.

I will:

1. **Check current git status** and ensure clean working directory
2. **Determine branch type** (feature, fix, chore) based on description or issue
3. **Generate proper branch name** following conventional naming patterns
4. **Create and switch to new branch** from current HEAD
5. **Set up upstream tracking** if pushing is needed
6. **Confirm successful branch creation** and provide next steps

### Branch Naming Convention

#### Automatic Detection

- **Issue numbers** (e.g., `42`, `#42`) → `feature/issue-42-description` or `fix/issue-42-description`
- **Bug keywords** (e.g., "fix", "bug") → `fix/description`
- **Feature keywords** (e.g., "add", "implement") → `feature/description`
- **Maintenance** (e.g., "refactor", "update") → `chore/description`

#### Format Examples

````text
feature/user-authentication
fix/login-validation-error
fix/issue-42-password-reset
feature/issue-15-dashboard-widgets
chore/update-dependencies
```text

### GitHub Issue Integration (Create)

When providing an issue number:

- Fetches issue title and labels from GitHub
- Automatically determines if it's a `fix/` or `feature/` based on labels
- Includes issue number in branch name for traceability
- Handles both `42` and `#42` formats

### Safety Features (Create)

- **Clean Working Directory**: Warns if there are uncommitted changes
- **Current Branch Context**: Shows what branch the new branch is created from
- **Duplicate Protection**: Checks if branch name already exists locally
- **Remote Awareness**: Fetches latest changes before branch creation

### Create Examples

```bash
# Create feature branch from description
/feature-branch create user authentication

# Create from GitHub issue (detects fix vs feature from labels)
/feature-branch create 42

# Create fix branch
/feature-branch create fix login bug
```text

---

## Switch to Feature Branch

Move current work from main/master/dev to a proper feature branch, preserving all uncommitted changes.

### Task (Switch)

I'll safely move your current work to a feature branch without losing any changes.

I will:

1. **Check current branch and status** - verify we're on a protected branch with changes
2. **Stash any uncommitted changes** to preserve work-in-progress
3. **Create new feature branch** with proper naming convention
4. **Apply stashed changes** to the new branch
5. **Verify all changes transferred** successfully
6. **Clean up stash** and confirm branch switch
7. **Provide next steps** for continuing work

### Use Cases (Switch)

Perfect for when you:

- Started working directly on `main`/`master` by mistake
- Have uncommitted changes you want to move to a proper feature branch
- Need to create a branch from existing work without losing progress
- Want to separate different features into different branches

### Safety Protocol (Switch)

#### Pre-flight Checks

- Only runs when on protected branches (`main`, `master`, `dev`)
- Confirms there are uncommitted changes to move
- Checks for any merge conflicts or git issues
- Warns about untracked files that might not transfer

#### Change Preservation

- Uses `git stash` to safely preserve all uncommitted changes
- Includes both staged and unstaged changes
- Preserves working directory state exactly

### Automatic Branch Naming (Switch)

If no description provided, uses:

- Current directory name
- First few words from recent commit messages
- Timestamp as fallback

### Manual Branch Naming (Switch)

Accepts descriptions like:

- `user authentication` → `feature/user-authentication`
- `fix login bug` → `feature/fix-login-bug`
- `refactor-api` → `feature/refactor-api`

### Error Recovery (Switch)

If something goes wrong:

```bash
# Check stash list
git stash list

# Return to original branch
git checkout main

# Clean up branch
git branch -D feature/branch-name

# Recover stash if needed
git stash apply stash@{0}
```text

### Switch Examples

```bash
# Switch with automatic naming
/feature-branch switch

# Switch with specific branch name
/feature-branch switch authentication

# Switch with fix description
/feature-branch switch fix-login-validation
```text

---

## Next Steps

After successful creation or switch:

- Continue development on the feature branch
- Use `/commit --push` when ready to share work
- Consider `/implement-issue <number>` if this relates to a GitHub issue
- Use `git log --oneline` to review what changes were made

## CLI References

**Git Operations**: See `@git-workflows` skill for:
- Checking status (`git status`)
- Getting current branch (`git branch --show-current`)
- Creating and switching branches (`git checkout -b`)
- Stashing operations (`git stash push`, `git stash pop`)

**GitHub Issue Operations**: See `@github-cli` skill for:
- Viewing issue details (`gh issue view`)
- Filtering by labels (`gh issue view --json`)
````
