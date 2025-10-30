---
name: Linear CLI
description: Query, create, and manage Linear issues from the command line. Use when checking assigned work, viewing issue details, creating new issues, or updating issue status.
---

# Linear CLI

Query, create, and update Linear issues without leaving the terminal.

## Most Used Commands

````bash
# Check your assigned work
linear-cli my-work

# View a single issue
linear-cli issue <issue-id>

# Create a new issue
linear-cli create --title "Issue title" --team-key ENG --priority 1

# Update status, assignee, or priority
linear-cli update <issue-id> --status "In Progress"

# Search across issues
linear-cli search "keyword"
```text

## Quick Examples

**Check what you're working on:**

```bash
linear-cli my-work
```text

**Create an urgent issue:**

```bash
linear-cli create --title "Production bug" --priority 1 --team-key ENG --description "Database failing"
```text

**Mark issue done with context:**

```bash
linear-cli update ENG-456 --status "Done"
linear-cli comment ENG-456 --message "Shipped in v2.1.0"
```text

## Key Flags

- `--team-key ENG` - Specify or filter by team
- `--status "In Progress"` - Set or filter by status
- `--priority 1` - Set priority (1-4, 1 is highest)
- `--assignee name` - Assign to team member
- `--description` - Add issue description

## More Info

See REFERENCE.md for complete flag documentation, advanced examples, and workflow patterns. Use `linear-cli --help` or `linear-cli <command> --help` for all options.

## Authentication

```bash
linear-cli login    # OAuth login (stores credentials)
linear-cli logout   # Clear stored credentials
linear-cli status   # Verify connection
```text
````
