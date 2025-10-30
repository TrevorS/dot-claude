# GitHub CLI Operations

Essential GitHub CLI (gh) commands for managing issues and pull requests directly from the command line.

## Most Used Commands

### Issue Operations

```bash
gh issue view <number>                      # View issue details
gh issue view <number> --json title,body    # View specific fields
gh issue list --assignee @me                # List issues assigned to me
gh issue create --title "Title" --body "Description"  # Create issue
gh issue edit <number> --title "New title"  # Edit issue
```

### Pull Request Operations

```bash
gh pr view <number>                         # View PR details
gh pr view <number> --json title,body       # View specific fields
gh pr list --assignee @me                   # List PRs assigned to me
gh pr create --title "Title" --body "Description"  # Create PR
gh pr review <number> --comment "Comment"   # Leave review comment
gh pr diff <number>                         # View PR diff
```

### API Access

```bash
gh api repos/<owner>/<repo>/pulls/<number>  # Get PR data
gh api repos/<owner>/<repo>/issues/<number> # Get issue data
gh api repos/<owner>/<repo>/pulls/<number>/comments  # Get PR comments
```

## Quick Examples

### View Issue Details

```bash
gh issue view 42
gh issue view 42 --json title,labels,author
```

### List Your Issues and PRs

```bash
gh issue list --assignee @me --state open
gh pr list --assignee @me --state open
```

### Create PR from Branch

```bash
# First, push your branch
git push -u origin feature/my-feature

# Create PR
gh pr create --title "My Feature" \
  --body "Description of changes"
```

### Review Pull Request

```bash
gh pr view 123 --json title,author,body
gh pr diff 123
gh pr review 123 --comment "Looks good!"
```

## Key Flags & Options

| Command         | Flag               | Purpose                   |
| --------------- | ------------------ | ------------------------- |
| `gh issue view` | `<number>`         | View specific issue       |
| `gh issue view` | `--json <fields>`  | Show specific JSON fields |
| `gh issue list` | `--assignee @me`   | Your assigned issues      |
| `gh issue list` | `--state open`     | Filter by state           |
| `gh pr view`    | `<number>`         | View specific PR          |
| `gh pr view`    | `--json <fields>`  | Show specific JSON fields |
| `gh pr diff`    | `<number>`         | Show PR changes           |
| `gh pr review`  | `--comment "text"` | Leave review comment      |
| `gh api`        | `<endpoint>`       | Direct API access         |

## Common JSON Fields

```bash
# For issues and PRs
title, number, author, labels, state, body, createdAt, updatedAt

# For PRs specifically
commits, files, reviews, comments, mergeable, baseRefName, headRefName

# Usage
gh pr view 42 --json title,author,labels,commits
gh issue view 42 --json title,labels,assignees
```

## Common Patterns

### Check Issue Before Starting Work

```bash
gh issue view <number> --json title,body,labels
# Read description and labels to understand requirements
```

### Link Branch to Issue

```bash
# Create branch following naming convention
git checkout -b feature/issue-<number>-description

# Create PR that automatically closes issue
gh pr create --title "Fix issue #<number>" \
  --body "Closes #<number>"
```

### Review Feedback Before Updating

```bash
gh pr view <number> --json reviews,comments
# Check review comments to understand feedback
```

## When to Use This Skill

Use this skill when:

- Viewing issue or PR details
- Listing issues or PRs assigned to you
- Creating issues or pull requests
- Leaving review comments
- Checking PR changes and reviews
- Using GitHub API directly

See `@git-workflows` for git branch and commit operations.
