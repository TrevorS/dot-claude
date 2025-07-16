# Implement GitHub Issue

GitHub issue: $ARGUMENTS

## Task

I'll **ultrathink** in order to develop a solution for this GitHub issue with careful context management.

I will:

1. **Check current git status** and ensure we're not working on main/master
2. **Create feature branch** with proper naming convention based on issue details
3. **Read and understand** the issue requirements using GitHub CLI
4. **Follow TDD approach** - write tests first
5. **Implement minimal code** to pass tests
6. **Refactor while maintaining** test coverage
7. **Document key decisions** in code
8. **Push to GitHub** with upstream tracking and create a pull request
9. **Keep the PR open** for review

## Branch Safety Protocol

Before starting implementation:

- Check current branch with `git branch --show-current`
- If on main/master/dev, create feature branch immediately
- Use GitHub CLI to fetch issue details for proper branch naming
- Format: `feature/issue-{number}-{short-description}` or `fix/issue-{number}-{short-description}`

## Pull Request Structure

- Title: [Issue #<number>] Short description of the change
- Description: Detailed explanation of the changes made
- Linked Issues: Reference to the GitHub issue
- Tests: Include tests that cover the new functionality
- Documentation: Update any relevant documentation

## Command Reference

```bash
# Check current branch
git branch --show-current

# View issue details
gh issue view <number>

# Create feature branch
git checkout -b "feature/issue-<number>-<description>"

# Create fix branch
git checkout -b "fix/issue-<number>-<description>"

# Push with upstream tracking
git push -u origin HEAD

# Search issues
gh issue list --search "in:title <keyword>"
```
