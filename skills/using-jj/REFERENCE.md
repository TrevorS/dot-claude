# jj Quick Reference

## History Surgery

```bash
jj squash --from X --into Y -m "msg" # Combine any two
jj absorb                            # Auto-route fixes to right ancestors
jj rebase -r @ -o <target>           # Move current change
jj rebase -s <src> -o <dest>         # Move change + descendants
```

## File Operations

```bash
jj restore --from @- <path>          # Undo file to parent state (any revset works)
jj file show -r <id> <path>          # Show file at revision
jj file search "pattern"             # Search file contents
```

**Untracking files**: If jj snapshotted a file before it was added to `.gitignore`, jj keeps tracking it even after the ignore rule exists. Use `jj file untrack <path>` to remove it from jj's tree while keeping it on disk. Do NOT use `jj restore --from <parent> <path>` — that deletes the file.

## Bookmarks & Push

```bash
# New feature branch
jj bookmark create feature-x -r @-
jj git push --bookmark feature-x

# Sync from remote
jj git fetch
jj rebase -o trunk()
```

## Recovery

```bash
jj op log                            # All operations
jj undo                              # Undo last
jj op restore <id>                   # Restore any state
jj evolog                            # Evolution of current change
jj evolog -r <change-id> -p          # Evolution with diffs
```

## Revset Cheatsheet

```text
@           Current change
@-          Parent
trunk()     Main branch
x::         Descendants of x
::x         Ancestors of x
x+          Children of x
x & y       Intersection
x | y       Union
trunk()..@  My branch
empty()     Empty commits
bookmarks() Bookmarked commits
divergent() Divergent changes
remote_tags() Remote tags
diff_lines() Commits with matching diff
xyz/0       Latest version of change xyz
xyz/1       Previous version of change xyz
```

## Git Equivalents

| Git                       | jj                                     |
| ------------------------- | -------------------------------------- |
| `git add . && git commit` | `jj commit -m "msg"`                   |
| `git commit --amend`      | Just edit files (auto-saved to `@`)    |
| `git stash`               | `jj new @- -m "other work"`            |
| `git stash pop`           | `jj edit <stashed-change-id>`          |
| `git rebase -i`           | `jj squash -m` / `jj absorb`           |
| `git reflog`              | `jj op log`                            |
| `git reset --hard`        | `jj op restore <id>`                   |
| `git branch`              | `jj bookmark`                          |
| `git grep`                | `jj file search "pattern"`             |
| `git checkout <branch>`   | `jj edit <change-id>`                  |
| `git cherry-pick`         | `jj duplicate <id>`                    |

## Troubleshooting

| Problem                   | Fix                                                                  |
| ------------------------- | -------------------------------------------------------------------- |
| Lost work                 | Recovery block above                                                 |
| Wrong parent              | `jj rebase -r @ -o <target>`                                         |
| Push rejected             | `jj git fetch && jj rebase -o trunk()`                               |
| @ is empty                | Your work is in `@-`; SKILL.md "Bookmarks & pushing"                 |
| "Immutable" error         | Pushed commit; work on a descendant, or pass `--ignore-immutable`    |
| Bookmark didn't move      | Bookmarks don't auto-advance; SKILL.md "Bookmarks & pushing"         |
| New bookmark push refused | `jj config set --user 'remotes.origin.auto-track-bookmarks' '*'`     |

## Parallel Experiments

```bash
jj new trunk() -m "approach A"        # Branch from trunk
jj new trunk() -m "approach B"        # Another branch from trunk (not from A)
jj diff --from <A-id> --to <B-id>     # Compare approaches
jj edit <winner-id>                   # Continue with the winner
jj abandon <loser-id>                 # Discard the loser
```

## Immutable Commits

To rewrite a commit protected by `immutable_heads()`, pass the global `--ignore-immutable` flag on that one command (for example `jj squash --into <id> --ignore-immutable`); no config change is needed.

## Config

User config is the stowed dotfile `dotfiles/jj/.config/jj/config.toml`, linked to `~/.config/jj/config.toml`.

## Bail Out

```bash
rm -rf .jj    # Delete jj state, keep git unchanged
```
