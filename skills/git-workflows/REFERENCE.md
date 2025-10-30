# Git Workflows - Complete Reference

Comprehensive reference for git commands, workflows, and advanced operations.

## Table of Contents

- [Branch Management](#branch-management)
- [Stash Operations](#stash-operations)
- [Commit Operations](#commit-operations)
- [History & Diff Commands](#history--diff-commands)
- [Advanced Operations](#advanced-operations)
- [Workflow Patterns](#workflow-patterns)
- [Recovery & Safety](#recovery--safety)
- [Troubleshooting](#troubleshooting)

## Branch Management

### Create Branches

```bash
git branch <branch-name>                    # Create branch locally
git checkout -b <branch-name>               # Create and switch in one step
git switch -c <branch-name>                 # Modern syntax (git 2.23+)
git branch <branch-name> <commit-hash>      # Create from specific commit
```

### Switch Branches

```bash
git checkout <branch-name>                  # Classic syntax
git switch <branch-name>                    # Modern syntax (git 2.23+)
git checkout -                              # Switch to previous branch
```

### List Branches

```bash
git branch                                  # List local branches
git branch -a                               # List local + remote branches
git branch -v                               # List with last commit info
git branch --list "feature/*"               # List matching pattern
```

### Rename Branches

```bash
git branch -m <new-name>                    # Rename current branch
git branch -m <old-name> <new-name>         # Rename specific branch
git push origin :<old-name> <new-name>      # Rename on remote (advanced)
```

### Delete Branches

```bash
git branch -d <branch-name>                 # Soft delete (safe, fails if unmerged)
git branch -D <branch-name>                 # Force delete (use with caution)
git push origin --delete <branch-name>      # Delete on remote
git push origin -d <branch-name>            # Delete on remote (short form)
```

### Check Current Branch

```bash
git branch --show-current                   # Show current branch name only
git rev-parse --abbrev-ref HEAD             # Alternative method
```

## Stash Operations

### Create Stashes

```bash
git stash                                   # Stash all changes
git stash push -m "message"                 # Stash with description
git stash push -u                           # Stash including untracked files
git stash push <file>                       # Stash specific file
git stash push -p                           # Interactive stash (patch mode)
```

### List Stashes

```bash
git stash list                              # List all stashes with indices
git stash list --oneline                    # Compact list format
git stash show stash@{0}                    # Show changes in stash
git stash show stash@{0} -p                 # Show stash contents with diff
```

### Apply Stashes

```bash
git stash pop                               # Apply most recent stash and remove
git stash pop stash@{0}                     # Apply specific stash and remove
git stash apply stash@{0}                   # Apply without removing
git stash apply                             # Apply most recent without removing
```

### Delete Stashes

```bash
git stash drop                              # Delete most recent stash
git stash drop stash@{0}                    # Delete specific stash
git stash clear                             # Delete all stashes (⚠️ irreversible)
```

### Stash Workflow: Switch Branches with Uncommitted Work

```bash
# Current situation: on main with uncommitted changes
git stash push -m "feature in progress"     # Save work
git checkout feature-branch                 # Switch safely
git stash list                              # Check your stashes
git stash pop                               # Restore work when back
```

## Commit Operations

### Creating Commits

```bash
git add .                                   # Stage all changes
git add <file>                              # Stage specific file
git add -p                                  # Interactive staging (patch mode)
git commit -m "message"                     # Quick commit with inline message
git commit -F /tmp/msg.txt                  # Commit with message from file
git commit --amend                          # Modify last commit (⚠️ changes history)
git commit --amend --no-edit                # Amend without changing message
```

### Pushing Commits

```bash
git push                                    # Push to tracked remote
git push -u origin HEAD                     # Push to remote with tracking setup
git push origin <branch-name>               # Push specific branch
git push origin --all                       # Push all branches
git push origin --tags                      # Push all tags
```

### Best Practice: Use Files for Commit Messages

```bash
# For complex messages, use a temporary file
cat > /tmp/commit-msg.txt << 'EOF'
Brief summary line (under 50 chars)

Detailed explanation of what changed and why.
Include any context or related issue numbers.

Fixes #123
EOF

git commit -F /tmp/commit-msg.txt
```

## History & Diff Commands

### View Commit History

```bash
git log                                     # Full commit history
git log --oneline                           # Compact one-line format
git log --oneline -5                        # Last 5 commits
git log --oneline -10                       # Last 10 commits
git log --graph --oneline --all             # Visual branch graph
git log <branch-name>                       # History of specific branch
git log --author="name"                     # Filter by author
git log --since="2 weeks ago"               # Filter by date range
```

### View Specific Commits

```bash
git show <commit-hash>                      # Show commit details and changes
git show <commit-hash>:file.txt              # Show file contents at commit
git log -p <file>                           # Show history of file with diffs
git blame <file>                            # Show who changed each line
```

### Compare Changes

```bash
git diff                                    # Show unstaged changes
git diff --staged                           # Show staged changes
git diff HEAD                               # Show all changes vs HEAD
git diff HEAD~1 HEAD                        # Compare last 2 commits
git diff <branch1> <branch2>                # Compare branches
git diff <commit1> <commit2>                # Compare any two commits
git range-diff <old-base>..<new-base>       # Compare commit ranges
```

## Advanced Operations

### History Rewriting (⚠️ Use with Caution)

These operations change commit history. Only use on unpushed commits.

```bash
git reset --soft HEAD~1                     # Undo last commit (keep changes staged)
git reset --mixed HEAD~1                    # Undo last commit (keep changes unstaged)
git reset --hard HEAD~1                     # Undo last commit (discard changes)
git reset --hard <commit-hash>              # Reset to specific commit
```

### Rebase Operations

```bash
git rebase <branch-name>                    # Rebase current branch onto another
git rebase -i HEAD~3                        # Interactive rebase last 3 commits
git rebase --continue                       # Continue after resolving conflicts
git rebase --abort                          # Cancel ongoing rebase
```

### Cherry-Pick

```bash
git cherry-pick <commit-hash>               # Apply specific commit to current branch
git cherry-pick <commit1> <commit2>         # Apply multiple commits
git cherry-pick --continue                  # Continue after resolving conflicts
```

### Range Operations

```bash
git range-diff main..feature                # Compare commits in feature vs main
git log main..feature --oneline             # Commits in feature but not in main
git diff main...feature                     # Combined diff of all commits
```

## Workflow Patterns

### Feature Branch Workflow

```bash
# 1. Create feature branch
git checkout -b feature/awesome-feature

# 2. Make changes, commit frequently
git add .
git commit -m "Add awesome feature"

# 3. Push to remote
git push -u origin HEAD

# 4. Create PR on GitHub
# (see @github-cli for PR creation)

# 5. After merge, clean up local
git checkout main
git pull
git branch -d feature/awesome-feature
```

### Safe History Rewriting

```bash
# Only rewrite unpushed commits
git log --oneline                           # Check commits
git reset --soft HEAD~3                     # Undo last 3 commits (keep changes)
git commit -m "Combined commit"             # Create new combined commit

# Or use interactive rebase
git rebase -i HEAD~3                        # Pick/squash/reword commits
```

### Stash-Based Branch Switch

```bash
# Current state: on main with work in progress
git stash push -m "Work on payment feature"
git checkout develop
git checkout -b bugfix/critical-issue
# ... fix bug ...
git checkout main
git stash pop                               # Restore payment work
```

### Commit Squashing Before PR

```bash
# Have multiple small commits, want to combine
git log --oneline -10                       # Review commits
git rebase -i HEAD~5                        # Interactive rebase
# In editor: keep first 'pick', change others to 'squash'
# Save and edit final commit message
git push -u origin HEAD
```

## Recovery & Safety

### Recover Deleted Branches

```bash
git reflog                                  # Show recent operations
git reflog show <branch-name>               # History of specific branch
git checkout -b <branch-name> <reflog-ref>  # Recover branch from reflog
```

### Recover Deleted Commits

```bash
git reflog                                  # Find deleted commit hash
git show <commit-hash>                      # Verify it's the right commit
git checkout -b recovered-branch <commit>   # Restore on new branch
```

### Safe Delete Workflow

```bash
git branch --list                           # List all branches
git log <branch-name> -10 --oneline         # Review branch before deleting
git branch -d <branch-name>                 # Soft delete (safe, won't delete unmerged)
git branch -D <branch-name>                 # Force delete (only if sure)
```

### Create Safety Branch Before Major Operation

```bash
git branch safety-backup                    # Create backup of current state
# ... perform risky operation ...
git diff safety-backup..HEAD                # Compare if needed
git branch -d safety-backup                 # Cleanup when confident
```

## Troubleshooting

### "Detached HEAD" State

Happens when you checkout a specific commit instead of a branch.

```bash
git branch --show-current                   # Will show "HEAD detached"
git checkout main                           # Switch back to a branch
# Or create a branch from current position
git checkout -b recovery-branch
```

### Merge Conflicts in Stash Apply

```bash
git stash pop                               # Attempt to apply
# If conflicts occur:
git status                                  # See conflicts
# Manually resolve conflicts in editor
git add .
git stash drop                              # Remove stash after resolving
```

### Undo Last Push (If Not Merged)

```bash
git log --oneline -3                        # Verify commit
git reset --soft HEAD~1                     # Undo locally
git push origin HEAD --force-with-lease     # Force push (safer than --force)
```

### Large File Accidentally Committed

```bash
git log --all --full-history -- <file>      # Find all occurrences
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch <file>' \
  --prune-empty --tag-name-filter cat -- --all
git push origin --force-with-lease          # Force push cleaned history
```

## Common Patterns by Scenario

| Scenario                         | Command                                            |
| -------------------------------- | -------------------------------------------------- |
| Switch branches safely with WIP  | `git stash push -m "msg"` then `git checkout`      |
| Create feature branch from issue | `git checkout -b feature/issue-<num>-description`  |
| Review branch before deleting    | `git log <branch> --oneline -10`                   |
| Combine multiple commits         | `git rebase -i HEAD~n` (interactive)               |
| Recover deleted branch           | `git reflog` then `git checkout -b <branch> <ref>` |
| Undo unpushed commits            | `git reset --soft HEAD~n`                          |
| View file at past commit         | `git show <commit>:<file>`                         |
| Find when bug was introduced     | `git log -p <file>` or `git blame <file>`          |
