# Linear CLI Reference

Workflow patterns and examples. For flags and options, use `linear-cli <command> --help`.

## Common Workflows

### Reading Comments

```bash
linear-cli comments ENG-456
```

### Starting a Task

```bash
# After `linear-cli create`, note the ID from its output, then:
linear-cli update ENG-789 --status "In Progress" --assignee me --force   # --force skips the confirmation prompt
```

### Filtering Issues

```bash
linear-cli issues --team ENG
linear-cli issues --status "In Progress"
linear-cli issues --assignee me
linear-cli issues --assignee me --creator katya   # assigned to me, opened by Katya
```

### Search

```bash
linear-cli search "authentication"
```
