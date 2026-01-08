---
name: jj-workflow
description: |
  Jujutsu (jj) version control for AI-assisted development. Use when:
  - Repo has `.jj/` directory (check with `jj root`)
  - Need undo/recovery after breaking changes
  - Curating messy history before PR
---

# jj Workflow

## Mental Model

**No staging area.** Your working directory is always a commit. Every save is tracked.

- `@` = your current change (the working copy)
- `@-` = parent of current change
- Changes are mutable until pushed

## When to Use What

| Situation             | Do This                                                   |
| --------------------- | --------------------------------------------------------- |
| Starting new work     | `jj new -m "what I'm trying"`                             |
| Work is done, move on | `jj new` (current becomes parent)                         |
| Annotate what you did | `jj describe -m "feat: auth"`                             |
| Broke something       | `jj op log` → `jj op restore <id>`                        |
| Undo one file         | `jj restore --from @- <path>`                             |
| Combine messy commits | `jj squash -m "message"` (use `-m` to avoid editor)       |
| Split bloated commit  | `jj split`                                                |
| Try something risky   | `jj new -m "experiment"`, then `jj abandon @` if it fails |

## AI Coding Pattern

During implementation, don't think about commits. Just work. jj tracks everything.

```bash
# Before risky change
jj describe -m "checkpoint: auth works"
jj new -m "adding OAuth"

# If it breaks
jj op log              # Find good state
jj op restore <id>     # Go back

# When done, curate
jj log -r 'ancestors(@, 10)'
jj squash -m "feat: OAuth support"  # -m avoids opening editor
```

## Push to GitHub

```bash
# For new branches
jj bookmark create feature-x -r @-   # Create at parent (the commit, not empty @)
jj git push                          # Push to remote

# For existing branches (like master)
jj bookmark set master -r @-         # Update bookmark to commit
jj git push                          # Push to remote

# If "nothing changed", fall back to git
git push origin master
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
