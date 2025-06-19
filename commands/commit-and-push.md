# Commit and Push Changes

Auto-stage, validate, commit with a clear message, and push changes to the remote repository.

## Task

I'll **think hard** to safely commit and push your work with proper validation and clear commit messaging.

I will:

1. **Check git status** and identify files that need staging
2. **Auto-stage relevant files** (modified, new files that make sense to include)
3. **Analyze changes** to understand the scope and nature of modifications
4. **Generate clear commit message** following repository conventions and your git workflow
5. **Create commit** using temporary file approach for clean message handling
6. **Push to origin** with appropriate branch tracking
7. **Provide summary** of all completed actions

## Commit Message Strategy

- Analyze `git diff --staged` and recent commit history to understand patterns
- Generate concise, descriptive messages that focus on the "why" not just "what"
- Follow repository conventions discovered from recent commits
- Use imperative mood (e.g., "Add feature" not "Added feature")
- Keep first line under 50 characters when possible
- Add detailed description if changes warrant explanation

## Safety Checks

- Check for merge conflicts or other git issues
- Ensure we're on the correct branch for pushing
- Handle cases where remote branch doesn't exist yet
- Stop and report if any validation step fails

## Command Reference

```bash
# Check current git status
git status --porcelain

# Stage all relevant changes
git add .

# Create commit with temporary file for message
cat > /tmp/commit-msg.txt << 'EOF'
[Generated commit message]
EOF
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt

# Push to remote
git push origin HEAD
```

## Error Handling

If any step fails:

- **Merge conflicts**: Guide through resolution process
- **Push failures**: Handle authentication, network, or branch protection issues
- **Staging issues**: Skip problematic files and report them separately
