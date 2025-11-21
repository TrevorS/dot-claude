# Git Workflow Reference

## Squashing Commits with `git reset --soft`

### Why This Method

- No editor interaction (reliable for automation)
- Intuitive: clearly shows what you're doing
- Safe: keeps changes staged for review

### Steps

```bash
# 1. Verify clean state
git status

# 2. Soft reset (keeps changes staged)
git reset --soft HEAD~3  # Adjust number as needed

# 3. Review what you're committing
git diff --cached

# 4. Commit with message
git commit -m "Your message"

# 5. Verify history
git log --oneline -5
```

### With Temporary File (Safer for Complex Messages)

```bash
cat > /tmp/msg.txt <<'EOF'
Your commit message here.
Multiple lines supported.
EOF

git commit -F /tmp/msg.txt
rm /tmp/msg.txt
```

### If Pre-Commit Hooks Modify Files

This is normal. After commit, if files changed:

```bash
git add .
git commit --amend --no-edit
```

---

## Rebasing Feature Branches

### Full Workflow

```bash
# 1. Create safety backup
git branch backup-$(date +%s)

# 2. Update dev branch
git fetch origin dev
git checkout dev
git pull

# 3. Go back to feature branch
git checkout my-feature

# 4. Rebase with clean timestamps
git rebase --committer-date-is-author-date dev

# 5. Handle conflicts if they occur (see below)

# 6. Force push (safe only for unpublished branches)
git push -f origin my-feature
```

### Understanding Timestamps

Git tracks two dates per commit:

- **Author date**: When you originally wrote the code
- **Committer date**: When the commit was created/modified

`--committer-date-is-author-date` makes committer date = author date, keeping your feature commits "on top" chronologically.

### Resolving Conflicts During Rebase

Git pauses when it finds conflicts. For each conflicted file:

```bash
# 1. Edit the file (resolve markers: <<<<<<, =======, >>>>>>)
# 2. Stage the fixed file
git add <filename>

# 3. Continue rebase
git rebase --continue
```

**Abort if needed:**

```bash
git rebase --abort  # Back to before the rebase
```

### Force Push Safety

Only use `git push -f` if:

- Branch hasn't been pushed yet
- Only you are working on this branch
- You're explicitly rewriting history on a feature branch

Never force-push `main`, `master`, or shared branches.

---

## Recovery

### Abort Current Rebase

```bash
git rebase --abort
```

### Recover Using Reflog

```bash
git reflog                    # See recent HEAD positions
git reset --hard <hash>       # Reset to that state
git push -f origin <branch>   # Update remote if needed
```

Reflog keeps references for ~90 days.

### Using Your Backup Branch

```bash
git reset --hard backup-<timestamp>
```

---

## Combined: Squash + Rebase

```bash
# 1. Backup
git branch backup-$(date +%s)

# 2. Squash
git reset --soft HEAD~5
git commit -m "Feature: description"

# 3. Update and rebase
git fetch origin dev && git checkout dev && git pull
git checkout my-feature
git rebase --committer-date-is-author-date dev

# 4. If hooks changed files:
git add .
git commit --amend --no-edit

# 5. Push
git push -f origin my-feature
```

---

## Troubleshooting

| Problem                                     | Solution                                                      |
| ------------------------------------------- | ------------------------------------------------------------- |
| "Rebase failed - repository not clean"      | `git stash` first, then rebase, then `git stash pop`          |
| "Nothing to commit" after reset             | Wrong number of commits. Try `git log --oneline` to count.    |
| Conflicts during rebase                     | Edit files, `git add .`, then `git rebase --continue`         |
| Need to keep all your changes in a conflict | `git checkout --ours . && git add . && git rebase --continue` |
| Merge conflict, want to abort               | `git rebase --abort`                                          |
| Already force-pushed but regretted          | `git reflog` to find original HEAD, `git reset --hard <hash>` |

---

## What NOT to Do

- Don't use `GIT_SEQUENCE_EDITOR` tricks
- Don't rebase shared branches (main, master, dev if others use it)
- Don't force-push to shared branches
- Don't rebase without updating the target branch first
- Don't use interactive rebase (`git rebase -i`) for squashing—use `reset --soft`
