---
name: cleaning-commit-history
description: Reorganize and clean up messy commit history on a feature branch into logical, reviewable commits. Use when cleaning up commits, preparing a branch for review, separating formatting from logic changes, fixing broken intermediate states, or squashing WIP commits.
context: fork
background: false
model: sonnet
---

# Cleaning Commit History

The oplog is the safety net.

## Operating Procedure

### Phase 0: Safety

Note the current operation ID with `jj op log -n 1`.

### Phase 1: Inventory

Determine the base branch, inventory feature-only changes with `jj log -r 'trunk()..@'`, and note large files, generated paths, vendored code, and migrations.

### Phase 2: Sea of Changes

Compute the net diff from BASE to FEATURE_BRANCH (not commit-by-commit).

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

**jj workflow**:

Pushed commits are immutable under the `remote_bookmarks()` config, hence `--ignore-immutable`; `rules/pr-safety.md` still gates whether the rewrite may happen at all.

```bash
# Squash related changes
jj squash --from <change1> --into <change2> --ignore-immutable -m "combined message"

# Split one change into several — non-interactive, needs BOTH paths and -m.
# The named paths go to the split-out commit; the rest stays in the child.
jj split -r <change> --ignore-immutable -m "first part" path/a path/b

# Reorder
jj rebase -r <change> -o <new-parent> --ignore-immutable

# If anything goes wrong
jj op restore <before-surgery>
```

### Phase 6: Validation

- `git diff $BASE..HEAD` equals the original sea (no loss of intent)

## Commit Message Style

Use the format in `committing-changes` (conventional type(scope), 72-char subject, bullets for why).

## Deliverables

1. **Commit Plan**: Ordered list with title, scope, type, rationale, and files
2. **Summary Report**: Changes vs original, tradeoffs, recovery instructions
