---
name: using-linear
description: Query, create, and manage Linear issues from the command line. Use when checking assigned work, viewing issue details, creating new issues, or updating issue status.
when_to_use: "Typed as 'what is assigned to me', 'create a ticket', 'move ENG-123 to done', or whenever a message contains a Linear issue key like ENG-456."
---

# Linear CLI

## Quick Examples

```bash
# Check your assigned work
linear-cli my-work

# View issue details
linear-cli issue ENG-456

# Create a new issue
linear-cli create --title "Production bug" --priority 1 --team ENG

# Update status and add comment
linear-cli update ENG-456 --status "Done" --force   # --force skips the confirmation prompt
linear-cli comment ENG-456 "Shipped in v2.1.0"
```

## Key Flags

- `--team ENG` - Specify or filter by team
- `--status "In Progress"` - Set or filter by status
- `--priority 1` - Set priority (1-4, 1 is highest)
- `--assignee name` - Assign to team member
- `--creator name` - Filter `issues` by who created them (`me` or a name substring)
- `--description` - Add issue description

Workflow examples in `REFERENCE.md`; flags via `linear-cli <command> --help`.

## Authentication

```bash
linear-cli login    # OAuth login (stores credentials)
linear-cli logout   # Clear stored credentials
linear-cli status   # Verify connection
```
