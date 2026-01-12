# jj Quick Patterns

## Squash Workflow (Recommended)

Start with intent, build up changes, squash when ready:

```bash
jj new -m "feat: building feature"   # State intent upfront
# ... make changes ...
jj squash -m "feat: done"            # Merge into parent (-m avoids editor)
```

**Note:** `jj squash` without `-m` opens an editor. Always use `-m "message"` for non-interactive use.

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

# Push requires a bookmark
jj bookmark set master -r @-         # Point bookmark at commit (not empty @)
jj git push                          # Push to remote

# For new branches
jj bookmark create feature-x -r @-
jj git push --bookmark feature-x
```

**Note:** If push is refused for new bookmarks, configure auto-tracking:

```bash
jj config set --user 'remotes.origin.auto-track-bookmarks' 'glob:*'
```

## Troubleshooting

| Problem             | Fix                                            |
| ------------------- | ---------------------------------------------- |
| Conflict            | Fix files, then `jj squash -m "resolve"`       |
| Lost work           | `jj op log` → `jj op restore`                  |
| Wrong parent        | `jj rebase -r @ -d <target>`                   |
| Push rejected       | `jj git fetch && jj rebase -d main`            |
| "Nothing changed"   | `jj bookmark set master -r @-` then push       |
| Squash opens editor | Use `jj squash -m "message"` instead           |
| @ is empty          | Your work is in `@-`; use `-r @-` for commands |

## Git Equivalents

| Git                       | jj                                       |
| ------------------------- | ---------------------------------------- |
| `git add . && git commit` | `jj new` (or `jj squash -m "msg"`)       |
| `git commit --amend`      | Just edit (auto-saved)                   |
| `git stash`               | `jj new && jj edit @-`                   |
| `git rebase -i`           | `jj squash -m` / `jj split`              |
| `git reflog`              | `jj op log`                              |
| `git reset --hard`        | `jj op restore`                          |
| `git branch`              | `jj bookmark`                            |
| `git push`                | `jj bookmark set X -r @- && jj git push` |
