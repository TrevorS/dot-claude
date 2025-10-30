# Git Workflows & Operations

Essential git commands and patterns for managing branches, commits, and history in your development workflow.

## Most Used Commands

### Branch Management

```bash
git branch --show-current          # Show current branch
git checkout -b <branch-name>      # Create and switch to branch
git checkout <branch-name>         # Switch to existing branch
git branch -m <new-name>           # Rename current branch
git branch -D <branch-name>        # Force delete branch (local)
```

### Stash Operations

```bash
git stash push -m "message"        # Stash changes with description
git stash pop                      # Apply and remove most recent stash
git stash apply stash@{0}          # Apply stash without removing
git stash list                     # List all stashes
```

### Commit Operations

```bash
git add .                          # Stage all changes
git commit -F /tmp/commit-msg.txt  # Commit with message from file
git push -u origin HEAD            # Push to remote with tracking
git push                           # Push to tracked remote
```

### History Review

```bash
git log --oneline                  # Show commit history (one line each)
git log --oneline -5               # Show last 5 commits
git diff HEAD~1 HEAD               # Show changes in last commit
git show <commit-hash>             # Show specific commit details
```

## Quick Examples

### Create and Push Feature Branch

```bash
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -F /tmp/msg.txt
git push -u origin HEAD
```

### Stash and Switch Branches

```bash
git stash push -m "work in progress"
git checkout main
git pull
git checkout feature/my-branch
git stash pop
```

### Review Commit History

```bash
git log --oneline -10
git diff HEAD~5..HEAD               # Changes from 5 commits ago to now
git show abc1234                    # View specific commit
```

## Key Flags & Options

| Command        | Flag             | Purpose                                   |
| -------------- | ---------------- | ----------------------------------------- |
| `git commit`   | `-m "message"`   | Inline message                            |
| `git commit`   | `-F <file>`      | Message from file (preferred for complex) |
| `git add`      | `.`              | Stage all changes                         |
| `git add`      | `<file>`         | Stage specific file                       |
| `git push`     | `-u origin HEAD` | Push with upstream tracking               |
| `git checkout` | `-b <name>`      | Create branch while checking out          |
| `git branch`   | `-D <name>`      | Force delete (use with caution)           |
| `git log`      | `--oneline`      | Compact one-line format                   |
| `git log`      | `-n <number>`    | Show last N commits                       |

## Common Patterns

### Safe Branch Deletion

Always verify before deleting:

```bash
git branch --list                   # List all branches
git log --oneline <branch> -5       # Review branch commits
git branch -d <branch>              # Soft delete (fails if not merged)
git branch -D <branch>              # Force delete (use with caution)
```

### Stash-Based Branch Switching

When you need to switch branches with uncommitted work:

```bash
git stash push -m "descriptive message"
git checkout <target-branch>
git stash list                      # Check your stashes
git stash pop                       # Apply the stash
```

### Commit Message Best Practices

Use files for complex messages:

```bash
# Write message to file
cat > /tmp/commit-msg.txt << 'EOF'
Short description

- Detailed explanation
- What changed and why
- Any related issue numbers
EOF

# Commit with the file
git commit -F /tmp/commit-msg.txt
```

## When to Use This Skill

Use this skill when:

- Managing branches (create, switch, delete)
- Stashing and recovering work
- Reviewing commit history
- Understanding git workflows
- Troubleshooting branch issues
- Planning commit strategies

See `@github-cli` for GitHub-specific operations like creating PRs or managing issues.
