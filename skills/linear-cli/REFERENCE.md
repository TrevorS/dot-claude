# Linear CLI Reference

Complete documentation for all commands, flags, and workflows.

## Table of Contents

- [All Commands](#all-commands)
- [Command Details](#command-details)
- [All Flags](#all-flags)
- [Advanced Examples](#advanced-examples)
- [Workflow Patterns](#workflow-patterns)
- [Tips & Troubleshooting](#tips--troubleshooting)

## All Commands

| Command          | Purpose                                 |
| ---------------- | --------------------------------------- |
| `my-work`        | Show assigned and created issues        |
| `issue <id>`     | Show details for a single issue         |
| `issues`         | List all issues (with optional filters) |
| `create`         | Create a new issue                      |
| `update <id>`    | Update an existing issue                |
| `close <id>`     | Close an issue (convenience)            |
| `reopen <id>`    | Reopen an issue (convenience)           |
| `comment <id>`   | Add a comment to an issue               |
| `comments <id>`  | Show all comments for an issue          |
| `search <query>` | Search issues, projects, and comments   |
| `projects`       | List all projects                       |
| `teams`          | List all teams                          |
| `status`         | Check connection to Linear              |
| `login`          | Authenticate via OAuth                  |
| `logout`         | Clear stored credentials                |
| `images`         | Manage image cache (requires feature)   |
| `completions`    | Generate shell completions              |

## Command Details

### View Issues

```bash
# Your work
linear-cli my-work

# Specific issue with full details
linear-cli issue ENG-456

# All issues, optionally filtered
linear-cli issues
linear-cli issues --team-key ENG
linear-cli issues --status "In Progress"

# Comments on an issue
linear-cli comments ENG-456
```text

### Create Issues

```bash
# Minimal creation
linear-cli create --title "Fix login bug"

# With team and priority
linear-cli create --title "Urgent fix" --team-key ENG --priority 1

# Full details
linear-cli create \
  --title "Feature request" \
  --team-key ENG \
  --description "Add dark mode support" \
  --priority 2 \
  --assignee "john@example.com"
```text

### Update Issues

```bash
# Change status
linear-cli update ENG-456 --status "In Progress"
linear-cli update ENG-456 --status "Done"

# Assign to self or others
linear-cli update ENG-456 --assignee "your-name"
linear-cli update ENG-456 --assignee "john@example.com"

# Adjust priority
linear-cli update ENG-456 --priority 1

# Multiple changes at once
linear-cli update ENG-456 --status "In Progress" --assignee "you" --priority 2
```text

### Comments

```bash
# Add a comment
linear-cli comment ENG-456 --message "Fixed in PR #789"

# View all comments
linear-cli comments ENG-456
```text

### Convenience Commands

```bash
# Quick close/reopen
linear-cli close ENG-456
linear-cli reopen ENG-456
```text

### Search

```bash
# Basic search
linear-cli search "authentication"

# Search results include issues, projects, and comments
linear-cli search "database connection"

# Pipe results for filtering
linear-cli search "bug" | grep "priority: 1"
```text

### Lists & Info

```bash
# Show all projects
linear-cli projects

# Show all teams
linear-cli teams

# Verify connection (useful for debugging)
linear-cli status
```text

## All Flags

### Common to Most Commands

| Flag            | Usage                           | Example                                   |
| --------------- | ------------------------------- | ----------------------------------------- |
| `--no-color`    | Disable colored output          | `linear-cli my-work --no-color`           |
| `--force-color` | Force color (useful when piped) | `linear-cli issues --force-color \| less` |
| `-v, --verbose` | Enable debug output             | `linear-cli issue ENG-456 -v`             |
| `-h, --help`    | Show help for command           | `linear-cli create --help`                |

### Create/Update Flags

| Flag            | Purpose                    | Example                        |
| --------------- | -------------------------- | ------------------------------ |
| `--title`       | Issue title                | `--title "Fix auth bug"`       |
| `--team-key`    | Team identifier            | `--team-key ENG`               |
| `--status`      | Issue status               | `--status "In Progress"`       |
| `--priority`    | Priority 1-4 (1 = highest) | `--priority 1`                 |
| `--assignee`    | Assign to person           | `--assignee "john"`            |
| `--description` | Full description           | `--description "Details here"` |
| `--message`     | Comment text               | `--message "Fixed in v1.2"`    |

### Filter Flags (for `issues` command)

| Flag         | Purpose            | Example              |
| ------------ | ------------------ | -------------------- |
| `--team-key` | Filter by team     | `--team-key ENG`     |
| `--status`   | Filter by status   | `--status "Backlog"` |
| `--assignee` | Filter by assignee | `--assignee "john"`  |

## Advanced Examples

### Bulk Operations

```bash
# Find all high-priority open issues in your team
linear-cli issues --team-key ENG | grep "priority: 1"

# Count issues by status
linear-cli issues --team-key ENG | grep "status:" | sort | uniq -c

# List all your assignments
linear-cli my-work | grep "assigned"
```text

### Creating Multiple Issues

```bash
# Create from a list
for title in "Fix login" "Add docs" "Refactor API"; do
  linear-cli create --title "$title" --team-key ENG --priority 2
done
```text

### Workflow: Sprint Kickoff

```bash
# View all backlog items for your team
linear-cli issues --team-key ENG --status "Backlog"

# Assign to team members and set to "In Progress"
linear-cli update ENG-100 --assignee "alice" --status "In Progress"
linear-cli update ENG-101 --assignee "bob" --status "In Progress"
```text

### Search-Based Workflows

```bash
# Find all issues mentioning "database"
linear-cli search "database"

# Find and view details on first result
linear-cli issue ENG-200
linear-cli comments ENG-200
```text

### Integration: Script to Update All Done Issues

```bash
#!/bin/bash
# Mark all "Ready for Review" issues as "In Review"
for issue_id in $(linear-cli issues --status "Ready for Review" | grep "ENG-" | awk '{print $1}'); do
  linear-cli update "$issue_id" --status "In Review"
  echo "Updated $issue_id"
done
```text

## Workflow Patterns

### Daily Standup

```bash
# Check your work
linear-cli my-work

# Dig into any blockers
linear-cli issue ENG-456
linear-cli comments ENG-456
```text

### Starting a Task

```bash
# Create issue if needed
linear-cli create --title "New feature" --team-key ENG

# Get the issue ID from output, then:
linear-cli update ENG-789 --status "In Progress" --assignee "you"
```text

### Closing Work

```bash
# Update status
linear-cli update ENG-456 --status "Done"

# Add context about the fix
linear-cli comment ENG-456 --message "Shipped in v2.1.0"
linear-cli comment ENG-456 --message "Fixed by PR #1234"
```text

### Triaging Bugs

```bash
# Search for recent bugs
linear-cli search "bug"

# Review each one
linear-cli issue ENG-111
linear-cli issue ENG-112

# Assign and prioritize
linear-cli update ENG-111 --assignee "alice" --priority 1 --status "In Progress"
```text

### Sprint Cleanup

```bash
# Find all "Done" issues in current sprint
linear-cli issues --team-key ENG --status "Done"

# Archive or close as needed
linear-cli close ENG-500
```text

## Tips & Troubleshooting

### Verify Connection

```bash
linear-cli status
```text

Confirms you're authenticated and connected to Linear.

### Get Help Anytime

```bash
linear-cli --help              # All commands
linear-cli <command> --help    # Specific command
```text

### Shell Completions

```bash
linear-cli completions
```text

Generate shell completions for bash, zsh, or fish to enable auto-completion.

### Custom Filtering with Grep

```bash
# Find high-priority issues
linear-cli issues | grep "priority: 1"

# Find your assignments
linear-cli my-work | grep "assigned"

# Search results and filter
linear-cli search "api" | grep "ENG-"
```text

### Debugging Issues

```bash
# Enable verbose output
linear-cli my-work -v

# Helps diagnose authentication or connection issues
linear-cli status -v
```text

### Re-authenticate

```bash
# If credentials seem stale
linear-cli logout
linear-cli login
```text

### Combining Commands

```bash
# Create, view, and comment in sequence
linear-cli create --title "Bug fix" --team-key ENG
# Note the ID from output (e.g., ENG-789), then:
linear-cli issue ENG-789
linear-cli comment ENG-789 --message "Working on it now"
linear-cli update ENG-789 --status "In Progress"
```text

### Status Values

Common status values across Linear instances:

- Backlog
- Todo
- In Progress
- In Review
- Done
- Cancelled

Your instance may have custom statuses—run `linear-cli issues` and check what statuses appear.

### Priority Levels

- `1` - Urgent/Highest
- `2` - High
- `3` - Medium
- `4` - Low
