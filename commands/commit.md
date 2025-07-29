# Commit Changes

Auto-stage, validate, and commit changes with a clear message for incremental development workflow.

## Task

I'll **think hard** to safely commit your work with proper validation and clear commit messaging for frequent, smaller commits.

I will:

1. **Check current branch status** - ensure we're not committing to main/master/dev
2. **Prompt for feature branch creation** if on protected branch
3. **Check git status** and identify files that need staging
4. **Auto-stage relevant files** (modified, new files that make sense to include)
5. **Analyze changes** to understand the scope and nature of modifications
6. **Generate clear commit message** following repository conventions and your git workflow
7. **Create commit** using temporary file approach and pre-commit hook handling
8. **Provide summary** of completed actions (no push)

## Commit Message Strategy

- Analyze `git diff --staged` and recent commit history to understand patterns
- Generate concise, descriptive messages that focus on the "why" not just "what"
- Follow repository conventions discovered from recent commits
- Use imperative mood (e.g., "Add feature" not "Added feature")
- Keep first line under 50 characters when possible
- Add detailed description if changes warrant explanation
- Optimize for incremental commits with smaller, focused changes

## Branch Safety Protocol

**MANDATORY FIRST STEP**: Check if we're on a protected branch

- If on `main`, `master`, or `dev`: **STOP** and offer to create feature branch
- Suggest branch name based on current work or ask for user input
- Use format: `feature/description` or `fix/description`

## Safety Checks

- **Protected Branch Check**: Never commit directly to main/master/dev without explicit confirmation
- **Branch Status**: Check if current branch exists and is properly set up
- **Merge Conflicts**: Check for merge conflicts or other git issues
- **Validation**: Stop and report if any validation step fails
- **Uncommitted Changes**: Warn about any files that won't be staged
- **Work-in-Progress**: Suitable for frequent commits during development

## Command Reference

```bash
# Check current branch
git branch --show-current

# Check git status
git status --porcelain

# Stage changes (selective or all)
git add .

# Create commit with message file
git commit -F /tmp/commit-msg.txt

# If commit fails due to pre-commit hooks: re-stage and retry once
git add . && git commit -F /tmp/commit-msg.txt

# Check recent commit history for message patterns
git log --oneline -10
```

## Incremental Development Focus

This command is designed for:

- **Frequent commits**: Small, logical changes during development
- **Work-in-progress**: Commits that represent incremental progress
- **Local development**: Building up commit history before pushing
- **TDD workflow**: Committing after each test/implementation cycle
- **Refactoring**: Small, safe changes that can be committed individually
- **Feature development**: Breaking down work into logical commit chunks

## Error Handling

If any step fails:

- **Pre-commit hook failures**: Re-stage changes and retry once only before stepping back
- **Merge conflicts**: Guide through resolution process
- **Staging issues**: Skip problematic files and report them separately
- **No changes to commit**: Report current status and suggest next steps

## Key Differences from /commit-and-push

- **No pushing**: Keeps changes local for continued development
- **Optimized for frequency**: Expects smaller, more frequent commits
- **Work-in-progress friendly**: Suitable for incomplete features
- **Development focused**: Part of iterative development workflow
- **Less ceremony**: Streamlined for quick commits during coding sessions
