---
name: jj-workflow
description: |
  Jujutsu (jj) version control for AI-assisted development. Use when:
  - Repo has `.jj/` directory (check with `jj root`)
  - Need undo/recovery after breaking changes
  - Curating messy history before PR
---

# jj Workflow

## CRITICAL: Avoid Interactive Mode

**Always use `-m` flag** to prevent jj from opening an editor:

```bash
# WRONG - opens editor, blocks AI
jj new
jj describe
jj squash

# CORRECT - non-interactive
jj new -m "message"
jj describe -m "message"
jj squash -m "message"
```

**Never use these interactive commands:**

- `jj split` - inherently interactive, no non-interactive mode

## Mental Model

**No staging area.** Your working directory is always a commit. Every save is tracked.

- `@` = your current change (the working copy)
- `@-` = parent of current change
- Changes are mutable until pushed

## When to Use What

| Situation             | Do This                                                   |
| --------------------- | --------------------------------------------------------- |
| Starting new work     | `jj new -m "what I'm trying"`                             |
| Work is done, move on | `jj new -m "next task"`                                   |
| Annotate what you did | `jj describe -m "feat: auth"`                             |
| Broke something       | `jj op log` → `jj op restore <id>`                        |
| Undo one file         | `jj restore --from @- <path>`                             |
| Combine messy commits | `jj squash -m "combined message"`                         |
| Try something risky   | `jj new -m "experiment"`, then `jj abandon @` if it fails |

## AI Coding Pattern

**Start with intent.** Before implementing, state what you're about to do:

```bash
jj new -m "feat: add user logout button"
# Now implement... jj tracks everything automatically
```

This keeps changes focused and gives meaningful `jj log` output while working.

```bash
# Checkpoint before risky changes
jj describe -m "checkpoint: auth works"
jj new -m "trying OAuth integration"

# If it breaks
jj op log              # Find good state
jj op restore <id>     # Go back

# When done, curate history
jj squash -m "feat: OAuth support"
```

## Push to GitHub

**Pushed commits are immutable.** You can't squash into or modify them. The safe pattern:

```bash
# 1. Abandon empty checkpoint commits cluttering history
jj log -r '::@'                      # Find checkpoints
jj abandon <change-ids>              # Remove empty ones

# 2. Describe your work (don't try to squash into immutable parent)
jj describe -m "feat: what you did"

# 3. Move bookmark to your commit and push
jj bookmark set master -r @
jj git push
```

**For feature branches (new):**

```bash
jj bookmark create feature-x -r @
jj git push --allow-new
```

**For feature branches (updating):**

```bash
jj bookmark set feature-x -r @
jj git push
```

Teammates see clean git. They don't know you used jj.

## Recovery

The oplog records every operation. Nothing is lost.

```bash
jj op log                      # See all operations
jj undo                        # Undo last operation
jj op restore <id>             # Jump to any past state
```

## Bail Out

```bash
rm -rf .jj    # Delete jj, keep git unchanged
```
