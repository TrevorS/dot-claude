# Commit and Push Changes

Auto-stage, validate, commit with a clear message, and push changes to the remote repository.

## Task

I'll **think hard** to safely commit and push your work with proper validation and clear commit messaging.

I will:

1. **Check current branch status** - ensure we're not committing to main/master/dev
2. **Prompt for feature branch creation** if on protected branch
3. **Check git status** and identify files that need staging
4. **Auto-stage relevant files** (modified, new files that make sense to include)
5. **Analyze changes** to understand the scope and nature of modifications
6. **Generate clear commit message** following repository conventions and your git workflow
7. **Create commit** using temporary file approach and pre-commit hook handling
8. **Push to origin** with upstream tracking (-u flag) for new branches
9. **Provide summary** of all completed actions

## Commit Message Strategy

- Analyze `git diff --staged` and recent commit history to understand patterns
- Generate concise, descriptive messages that focus on the "why" not just "what"
- Follow repository conventions discovered from recent commits
- Use imperative mood (e.g., "Add feature" not "Added feature")
- Keep first line under 50 characters when possible
- Add detailed description if changes warrant explanation

## Branch Safety Protocol

**MANDATORY FIRST STEP**: Check if we're on a protected branch

- If on `main`, `master`, or `dev`: **STOP** and offer to create feature branch
- Suggest branch name based on current work or ask for user input
- Use format: `feature/description` or `fix/description`

## Safety Checks

- **Protected Branch Check**: Never commit directly to main/master/dev without explicit confirmation
- **Branch Status**: Check if current branch tracks a remote branch
- **Merge Conflicts**: Check for merge conflicts or other git issues
- **Remote Tracking**: Handle cases where remote branch doesn't exist (use `-u` flag)
- **Validation**: Stop and report if any validation step fails
- **Uncommitted Changes**: Warn about any files that won't be staged

## Command Reference

```bash
# Check current branch
git branch --show-current

# Check git status
git status --porcelain

# Stage changes
git add .

# Create commit with message file
git commit -F /tmp/commit-msg.txt

# If commit fails due to pre-commit hooks: re-stage and retry once
git add . && git commit -F /tmp/commit-msg.txt

# Push with upstream (new branches)
git push -u origin HEAD

# Push without upstream (existing)
git push origin HEAD

# Check upstream tracking
git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
```

## Error Handling

If any step fails:

- **Pre-commit hook failures**: Re-stage changes and retry once only before stepping back
- **Merge conflicts**: Guide through resolution process
- **Push failures**: Handle authentication, network, or branch protection issues
- **Staging issues**: Skip problematic files and report them separately
