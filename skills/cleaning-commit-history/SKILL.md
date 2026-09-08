---
name: cleaning-commit-history
description: Reorganize and clean up messy commit history on a feature branch into logical, reviewable commits. Use when cleaning up commits, preparing a branch for review, separating formatting from logic changes, fixing broken intermediate states, or squashing WIP commits.
context: fork
background: false
model: sonnet
---

# Cleaning Commit History

Detect the VCS with `jj root`; prefer jj (the oplog is the safety net).

## Operating Procedure

### Phase 0: Safety

Run the PR-safety check first (`rules/pr-safety.md`): if the branch has an open PR with review activity, ask before rewriting anything.

**Git**: Create backup branch before any surgery:

```bash
git branch ${CURRENT_BRANCH}-backup
```

**jj**: Not needed -- oplog provides safety. Note the current operation ID with `jj op log -n 1`.

### Phase 1: Inventory

Determine the base branch, inventory feature-only changes with `git log --oneline $BASE..$FEATURE_BRANCH`, and note large files, generated paths, vendored code, and migrations.

### Phase 2: Sea of Changes

Compute the net diff from BASE to FEATURE_BRANCH (not commit-by-commit). This represents all changes that need reorganization.

### Phase 3: Classify & Cluster

Cluster changes into logical buckets (strict priority):

1. **Generated/Vendored/Lockfiles** -- isolated to dedicated commits
2. **Pure renames/moves** -- separated from content changes
3. **Formatting-only** (whitespace, import order, lint fixes) -- isolated
4. **Refactors without behavior change** -- separate from logic
5. **Feature/Logic changes** -- grouped by cohesive unit
6. **Tests** -- co-located with their corresponding logic changes

**Split** when a commit mixes mechanical and semantic changes. **Squash** when multiple tiny edits serve the same concern.

### Phase 4: Determine Commit Order

Order for buildability and minimal noise:

1. Pure renames/moves
2. Formatting-only sweep
3. Refactors (non-behavioral)
4. Schema/Migrations
5. Feature/Logic in dependency order
6. Tests (accompany or immediately follow their logic)
7. Docs/Changelog
8. Vendored/lockfile updates

Every intermediate state must build and pass tests.

### Phase 5: Rebuild Commits

**Git**: `git reset --mixed $BASE`, then stage specific files per planned commit with `git add <files>`.

**jj workflow**:

```bash
# Squash related changes
jj squash --from <change1> --into <change2> -m "combined message"

# Split one change into several — non-interactive, needs BOTH paths and -m.
# The named paths go to the split-out commit; the rest stays in the child.
jj split -r <change> -m "first part" path/a path/b

# Reorder
jj rebase -r <change> -d <new-parent>

# Clean up messages
jj describe -m "feat(scope): message"

# If anything goes wrong
jj op restore <before-surgery>
```

### Phase 6: Validation

- `git diff $BASE..HEAD` equals the original sea (no loss of intent)
- Every commit builds and tests successfully

## Commit Message Style

Use the format in `committing-changes` (conventional type(scope), 72-char subject, bullets for why).

## Deliverables

1. **Commit Plan**: Ordered list with title, scope, type, rationale, and files
2. **Summary Report**: Changes vs original, tradeoffs, recovery instructions
