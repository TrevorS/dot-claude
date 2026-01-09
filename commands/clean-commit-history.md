# Clean Commit History

<!-- ABOUTME: Launches git-commit-surgeon agent to reorganize messy commit history into clean, logical sequences -->

<!-- ABOUTME: Creates safety backup branch before performing any commit surgery operations -->

Clean up a messy feature branch into a logical commit history that's easy to review and debug.

Usage: `/clean-commit-history [branch-name]`

## Task

I'll launch the git-commit-surgeon agent to analyze your feature branch and rebuild a clean commit history that separates concerns and creates atomic, reviewable commits.

I will:

1. **Create safety backup branch** to preserve original work (`${CURRENT_BRANCH}-backup`)
2. **Launch git-commit-surgeon agent** with specialized commit reorganization expertise
3. **Analyze current commit history** and identify improvement opportunities
4. **Create commit plan** showing proposed reorganization structure
5. **Execute commit surgery** following best practices for maintainability
6. **Validate results** ensuring no work is lost and all commits build/test

## When to Use This Command

### Perfect Use Cases

- **Mixed concerns**: Commits that combine formatting with logic changes
- **WIP commits**: Series of "fix", "temp", "wip" commits cluttering history
- **Broken intermediate states**: Commits that don't build or pass tests
- **Review preparation**: Making branch ready for clean code review
- **Atomic commit violations**: Large commits mixing multiple unrelated changes

### Example Scenarios

```text
Before: fix typo → add feature → fix build → temp commit → another fix
After:  refactor: extract helper functions → feat: implement user auth → test: add auth validation
```

## Safety Features

- **Automatic backup creation**: Original work preserved in `${CURRENT_BRANCH}-backup`
- **Validation checks**: Ensures no code changes are lost during reorganization
- **Build verification**: Each new commit is verified to build and pass tests
- **Recovery instructions**: Clear guidance on restoring from backup if needed

## Commit Reorganization Principles

The surgeon follows these strict priorities:

1. **Generated/Vendored/Lockfiles** → isolated to dedicated commits
2. **Pure renames/moves** → separated from content changes
3. **Formatting-only changes** → isolated sweep commits
4. **Refactors without behavior change** → separate from logic
5. **Feature/Logic changes** → grouped by cohesive functionality
6. **Tests** → co-located with their corresponding logic changes

## Command Reference

```bash
# Safety backup (automatic)
git branch ${CURRENT_BRANCH}-backup

# View original history
git log --oneline HEAD~10..HEAD

# Compare before/after
git range-diff backup-branch..old-branch backup-branch..new-branch

# Recover from backup if needed
git reset --hard ${CURRENT_BRANCH}-backup
```

## Quality Guarantees

The surgeon ensures:

- **No lost changes**: `git diff` before/after shows identical net changes
- **Atomic commits**: Each commit represents one logical change
- **Buildable history**: Every intermediate commit builds and tests pass
- **Clean messages**: Follows conventional commit format with clear rationales
- **Reviewer-friendly**: Easy to review and debug with git bisect

## Recovery Process

If you need to restore the original history:

```bash
# Switch back to backup
git reset --hard ${CURRENT_BRANCH}-backup

# Delete surgery attempt (optional)
git branch -D ${CURRENT_BRANCH}

# Rename backup to original
git branch -m ${CURRENT_BRANCH}-backup ${CURRENT_BRANCH}
```

## jj Alternative

If jj (jujutsu) is available, history surgery is simpler:

```bash
jj squash -m "combined message"   # Combine commits (always use -m!)
jj describe -m "new msg"          # Edit message
jj op restore <id>                # Undo any mistake
```

**Note:** `jj split` is inherently interactive and cannot be used in AI workflows. Use selective `jj restore` operations instead.

No backup branch needed—oplog provides automatic safety. The git-commit-surgeon agent will use jj commands when available.

## Agent Integration

This command launches the specialized `git-commit-surgeon` agent that:

- Has deep expertise in git/jj history manipulation
- Follows systematic approach to commit reorganization
- Prioritizes safety and recoverability above all else
- Produces detailed commit plans before making changes
- Validates every step to ensure no work is lost
