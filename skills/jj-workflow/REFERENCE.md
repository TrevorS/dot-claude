# jj Quick Patterns

## Squash Workflow (Recommended)

Build up changes incrementally, squash when ready:

```bash
jj describe -m "wip: building feature"
jj new                               # Work in fresh change
# ... make changes ...
jj squash                            # Merge into parent
jj squash -i                         # Pick specific hunks
```

## History Surgery

```bash
jj squash                            # Current into parent
jj squash --from X --into Y          # Combine any two
jj split                             # Break current into pieces
jj split -i                          # Interactive hunk selection
jj rebase -r @ -d <target>           # Move current change
```

## Parallel Experiments

```bash
jj new main -m "approach A"          # Branch A from main
jj new main -m "approach B"          # Branch B from main (not from A)
jj edit <change-id>                  # Switch between them
jj abandon <change-id>               # Discard loser
jj diff --from A --to B              # Compare approaches
```

## File Operations

```bash
jj restore --from @- <path>          # Undo file to parent state
jj restore --from <id> <path>        # Restore from any change
jj diff <path>                       # Diff specific file
jj cat -r <id> <path>                # Show file at revision
```

## Syncing

```bash
jj git fetch                         # Pull remote
jj rebase -d main                    # Rebase onto main
jj git push --allow-new              # Push (creates remote branch)
```

## Troubleshooting

| Problem       | Fix                                 |
| ------------- | ----------------------------------- |
| Conflict      | Fix files, then `jj squash`         |
| Lost work     | `jj op log` → `jj op restore`       |
| Wrong parent  | `jj rebase -r @ -d <target>`        |
| Push rejected | `jj git fetch && jj rebase -d main` |

## Git Equivalents

| Git                       | jj                       |
| ------------------------- | ------------------------ |
| `git add . && git commit` | `jj new`                 |
| `git commit --amend`      | Just edit (auto-saved)   |
| `git stash`               | `jj new && jj edit @-`   |
| `git rebase -i`           | `jj squash` / `jj split` |
| `git reflog`              | `jj op log`              |
| `git reset --hard`        | `jj op restore`          |
| `git branch`              | `jj bookmark`            |
