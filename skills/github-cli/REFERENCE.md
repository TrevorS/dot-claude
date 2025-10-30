# GitHub CLI - Complete Reference

Comprehensive reference for GitHub CLI commands, workflows, and advanced operations.

## Table of Contents

- [Issue Operations](#issue-operations)
- [Pull Request Operations](#pull-request-operations)
- [API Access](#api-access)
- [JSON Field Selection](#json-field-selection)
- [List Filtering](#list-filtering)
- [Workflow Patterns](#workflow-patterns)
- [Advanced Examples](#advanced-examples)
- [Tips & Troubleshooting](#tips--troubleshooting)

## Issue Operations

### View Issues

```bash
gh issue view <number>                          # View issue in terminal
gh issue view <number> --json <fields>          # View specific fields
gh issue view <number> --web                    # Open in browser
gh issue view                                   # View current issue (if in repo)
```

### List Issues

```bash
gh issue list                                   # List open issues
gh issue list --assignee @me                    # Issues assigned to you
gh issue list --author @me                      # Issues created by you
gh issue list --state all                       # Open and closed
gh issue list --label "bug"                     # Filter by label
gh issue list --limit 20                        # Show 20 issues
gh issue list --order asc                       # Oldest first
```

### Create Issues

```bash
gh issue create                                 # Interactive creation
gh issue create --title "Bug: login broken"     # With title
gh issue create --title "Feature" --body "Description"
gh issue create --title "Title" --label "bug,urgent"
gh issue create --assignee <username>
gh issue create --label "bug" --milestone "1.0"
```

### Edit Issues

```bash
gh issue edit <number> --title "New title"
gh issue edit <number> --body "New description"
gh issue edit <number> --add-label "priority-high"
gh issue edit <number> --remove-label "wontfix"
gh issue edit <number> --add-assignee <username>
gh issue edit <number> --remove-assignee <username>
```

### Close & Reopen

```bash
gh issue close <number>                         # Close issue
gh issue close <number> --reason "not_planned"  # Close with reason
gh issue reopen <number>                        # Reopen issue
```

## Pull Request Operations

### View PRs

```bash
gh pr view <number>                             # View PR in terminal
gh pr view <number> --json <fields>             # View specific fields
gh pr view <number> --web                       # Open in browser
gh pr view                                      # View current PR (if in repo)
```

### List PRs

```bash
gh pr list                                      # List open PRs
gh pr list --assignee @me                       # PRs assigned to you
gh pr list --author @me                         # PRs created by you
gh pr list --state all                          # Open and closed
gh pr list --base main                          # PRs targeting main
gh pr list --head feature/my-feature            # PR from specific branch
```

### Create PRs

```bash
gh pr create                                    # Interactive creation
gh pr create --title "Title" --body "Description"
gh pr create --title "Title" --base main --head feature/branch
gh pr create --title "Title" --draft             # Create as draft
gh pr create --title "Title" --assignee <user>
gh pr create --title "Closes #123"              # Link to issue
```

### PR Details

```bash
gh pr view <number> --json title,body,author    # View fields
gh pr diff <number>                             # Show changes
gh pr diff <number> --color                     # Colored diff
gh pr view <number> --json commits --jq '.commits | length'
```

### Review PRs

```bash
gh pr review <number>                           # Interactive review
gh pr review <number> --approve                 # Approve
gh pr review <number> --request-changes         # Request changes
gh pr review <number> --comment "Looks good!"   # Comment
gh pr review <number> --body "Review notes"     # Multi-line comment
```

### Merge PRs

```bash
gh pr merge <number>                            # Merge PR
gh pr merge <number> --squash                   # Squash and merge
gh pr merge <number> --rebase                   # Rebase and merge
gh pr merge <number> --delete-branch             # Delete branch after merge
```

## API Access

### Direct API Calls

```bash
gh api <endpoint>                               # GET request
gh api -H "Accept: application/vnd.github.v3.raw" <endpoint>
gh api -m POST <endpoint> -f field="value"
gh api -m PATCH <endpoint> -f field="value"
```

### Common Endpoints

```bash
# Get PR info
gh api repos/<owner>/<repo>/pulls/<number>

# Get issue info
gh api repos/<owner>/<repo>/issues/<number>

# Get PR comments
gh api repos/<owner>/<repo>/pulls/<number>/comments

# Get PR reviews
gh api repos/<owner>/<repo>/pulls/<number>/reviews

# List PR files
gh api repos/<owner>/<repo>/pulls/<number>/files
```

### API Examples

```bash
# Get PR merged status
gh api repos/TrevorS/dot-claude/pulls/7 --jq '.merged'

# Get PR review comments
gh api repos/TrevorS/dot-claude/pulls/7/comments --jq '.[] | {body, author}'

# Get PR files changed
gh api repos/TrevorS/dot-claude/pulls/7/files --jq '.[] | {filename, changes}'
```

## JSON Field Selection

### Common Issue/PR Fields

| Field        | Description            |
| ------------ | ---------------------- |
| `number`     | Issue or PR number     |
| `title`      | Title/subject line     |
| `body`       | Full description/body  |
| `author`     | Author/creator info    |
| `state`      | "open" or "closed"     |
| `labels`     | Associated labels      |
| `assignees`  | Assigned to users      |
| `created_at` | Creation timestamp     |
| `updated_at` | Last updated timestamp |

### PR-Specific Fields

| Field         | Description             |
| ------------- | ----------------------- |
| `commits`     | Number of commits       |
| `files`       | Number of files changed |
| `additions`   | Lines added             |
| `deletions`   | Lines deleted           |
| `mergeable`   | Can be merged           |
| `merged`      | Is merged               |
| `baseRefName` | Target branch           |
| `headRefName` | Source branch           |
| `reviews`     | Review objects          |
| `comments`    | Comments array          |

### Query Examples

```bash
# View selected fields
gh pr view 42 --json number,title,author,labels

# Get author name
gh pr view 42 --json author --jq '.author.login'

# Get list of files
gh pr view 42 --json files --jq '.files[] | .path'

# Check if PR is merged
gh pr view 42 --json merged --jq '.merged'

# Get commit count
gh pr view 42 --json commits --jq '.commits | length'
```

## List Filtering

### Filter Operators

```bash
--state open|closed|all
--assignee <username>|@me
--author <username>|@me
--label "<label>"
--base <branch>
--head <branch>
--limit <number>
--order asc|desc
--sort created|updated|comments
```

### Combination Examples

```bash
# Open bugs assigned to me
gh issue list --state open --label "bug" --assignee @me

# PRs created by you on feature branch
gh pr list --author @me --head "feature/*"

# Recent issues updated in last week
gh issue list --state all --sort updated --order desc --limit 10

# Closed issues with specific label
gh issue list --state closed --label "documentation"
```

## Workflow Patterns

### Issue to PR Workflow

```bash
# 1. Check issue details
gh issue view 42 --json title,body

# 2. Create feature branch
git checkout -b feature/issue-42-description

# 3. Make changes and commit
git add .
git commit -m "Implement feature for issue #42"

# 4. Push branch
git push -u origin feature/issue-42-description

# 5. Create PR linking to issue
gh pr create --title "Implement feature (closes #42)" \
  --body "Closes #42"

# 6. Get PR review feedback
gh pr view --json reviews

# 7. After approval, merge
gh pr merge --squash --delete-branch
```

### Daily Standup Check

```bash
# Check issues assigned to you
gh issue list --assignee @me --state open --limit 5

# Check PRs assigned to you
gh pr list --assignee @me --state open --limit 5

# Check PRs you created
gh pr list --author @me --state open --limit 5
```

### Review Workflow

```bash
# Get PR to review
gh pr view 123 --json title,author,body

# View changes
gh pr diff 123

# Get comments/reviews
gh pr view 123 --json reviews,comments

# Leave review
gh pr review 123 --request-changes --comment "Please update X"

# Or approve
gh pr review 123 --approve
```

## Advanced Examples

### Extract PR Data

```bash
# Get all files changed in PR
gh pr view 42 --json files --jq '.files[] | {path: .path, changes: .changes}'

# Get review comments with authors
gh pr view 42 --json comments --jq '.comments[] | {author: .author.login, body}'

# Get list of reviewers
gh pr view 42 --json reviews --jq '.reviews[] | .author.login' | sort | uniq
```

### Query Multiple PRs

```bash
# Get titles of last 10 merged PRs
gh pr list --state closed --limit 10 --json title,merged --jq '.[] | select(.merged) | .title'

# Find PRs by multiple labels
gh pr list --state open --label "bug,priority-high" --limit 20

# List open PRs with file count
gh pr list --json number,title,files --jq '.[] | {number, title, files: .files | length}'
```

### Bulk Operations

```bash
# Add label to multiple issues
gh issue list --state open --label "needs-review" --json number \
  --jq '.[] | .number' | xargs -I {} gh issue edit {} --add-label "reviewed"

# Close issues with specific label
gh issue list --label "wontfix" --state open --json number \
  --jq '.[] | .number' | xargs -I {} gh issue close {}
```

## Tips & Troubleshooting

### Authentication

```bash
gh auth login                                   # Login
gh auth status                                  # Check login status
gh auth logout                                  # Logout
```

### Common Errors

| Error                  | Solution                                                   |
| ---------------------- | ---------------------------------------------------------- |
| "Repository not found" | Ensure you're in a git repo or specify `--repo owner/name` |
| "Not authenticated"    | Run `gh auth login` first                                  |
| "Validation failed"    | Check required fields (e.g., PR needs base branch)         |
| "Could not parse"      | Verify JSON field names exist for your PR/issue state      |

### Useful Flags

```bash
--repo owner/repo           # Specify repo (when not in repo directory)
--json <fields>             # Output specific fields (default: formatted text)
--jq <filter>              # Use jq to filter JSON output
--help                     # Show command help
```

### Debug Output

```bash
# See full JSON output
gh pr view 42 --json title,body,author

# Use jq to explore available fields
gh pr view 42 | gh api - --input - | jq 'keys'

# Pretty print
gh pr view 42 --json number,title,author | jq '.'
```

### Performance Tips

1. Use `--limit` to restrict results: `gh issue list --limit 5`
2. Use `--json` to get only needed fields (faster than default format)
3. Use specific filters rather than listing all: `gh issue list --assignee @me`
4. Cache credentials: `gh auth login --web`

### Using with Other Tools

```bash
# List issue numbers and pipe to other commands
gh issue list --json number --jq '.[] | .number'

# Get PR data and format with awk
gh pr list --json title,author --jq '.[]' | awk '{print $1 " by " $2}'

# Export to CSV (using jq)
gh pr list --json number,title,author --jq '.[] | [.number, .title, .author.login] | @csv'
```
