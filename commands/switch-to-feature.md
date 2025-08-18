# Switch to Feature Branch

<!-- ABOUTME: Moves work from protected branches to feature branches safely -->

<!-- ABOUTME: Preserves all uncommitted changes using git stash during transfer -->

Move current work from main/master/dev to a proper feature branch, preserving all uncommitted changes.

Usage: `/switch-to-feature [branch-name-or-description]`

## Task

I'll safely move your current work to a feature branch without losing any changes.

I will:

1. **Check current branch and status** - verify we're on a protected branch with changes
2. **Stash any uncommitted changes** to preserve work-in-progress
3. **Create new feature branch** with proper naming convention
4. **Apply stashed changes** to the new branch
5. **Verify all changes transferred** successfully
6. **Clean up stash** and confirm branch switch
7. **Provide next steps** for continuing work

## Use Cases

Perfect for when you:

- Started working directly on `main`/`master` by mistake
- Have uncommitted changes you want to move to a proper feature branch
- Need to create a branch from existing work without losing progress
- Want to separate different features into different branches

## Safety Protocol

### Pre-flight Checks

- Only runs when on protected branches (`main`, `master`, `dev`)
- Confirms there are uncommitted changes to move
- Checks for any merge conflicts or git issues
- Warns about untracked files that might not transfer

### Change Preservation

- Uses `git stash` to safely preserve all uncommitted changes
- Includes both staged and unstaged changes
- Preserves working directory state exactly

## Command Reference

```bash
# Check current branch
git branch --show-current

# Check for uncommitted changes
git status --porcelain

# Stash changes with message
git stash push -m "switch-to-feature: Moving work"

# Create new feature branch
git checkout -b "feature/description"

# Apply stashed changes
git stash pop

# List stashes
git stash list

# Recover specific stash
git stash apply stash@{0}
```

## Branch Naming

### Automatic Naming

If no description provided, uses:

- Current directory name
- First few words from recent commit messages
- Timestamp as fallback

### Manual Naming

Accepts descriptions like:

- `user authentication` → `feature/user-authentication`
- `fix login bug` → `feature/fix-login-bug`
- `refactor-api` → `feature/refactor-api`

## Error Recovery

If something goes wrong:

```bash
# Check stash list
git stash list

# Return to original branch
git checkout main

# Clean up branch
git branch -D feature/branch-name
```

## Next Steps

After successful switch:

- Continue development on the feature branch
- Use `/commit-and-push` when ready to share work
- Consider `/implement-issue <number>` if this relates to a GitHub issue
- Use `git log --oneline` to review what changes were moved

## Advanced Options

### For Complex Scenarios

- **Selective stashing**: Move only specific files to feature branch
- **Multiple stashes**: Handle different features in separate stashes
- **Conflict resolution**: Guidance for merge conflicts during stash application
- **Remote tracking**: Set up upstream immediately if pushing soon
