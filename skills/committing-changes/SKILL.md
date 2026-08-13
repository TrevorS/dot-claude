---
name: committing-changes
description: Stage, validate, and commit changes with a clear message, optionally pushing to remote and monitoring CI. Use when committing code, creating a commit, pushing changes, or doing a commit-and-push workflow.
argument-hint: "[--push] [message hint]"
---

# Committing Changes

Auto-stage, validate, and commit changes. Pass `--push` to also push and monitor CI.

## Workflow

### 1. Detect VCS

```bash
if jj root 2>/dev/null; then
  # USE JJ WORKFLOW
else
  # USE GIT WORKFLOW
fi
```

**CRITICAL: Always use `-m` flag with jj** to prevent editor from blocking.

### 2. Check Branch Safety

Check `./CLAUDE.md` **and** `./.claude/CLAUDE.md` for a `direct-commits-allowed: true` marker. If on a protected branch without it, suggest a feature branch. Cache decisions for future runs.

### 3. Run Validation

Auto-detect project type and run: format -> lint -> typecheck. Stop on failure.

### 4. Craft Commit Message

Use **conventional commits** format: `type(scope): description`

Valid types: `feat`, `fix`, `refactor`, `docs`, `style`, `perf`, `test`, `build`, `ci`, `chore`.

Choose type from the diff:

- New functionality → `feat`
- Bug fix → `fix`
- Code restructuring without behavior change → `refactor`
- CI/CD config → `ci`
- Build system, deps → `build`
- Documentation → `docs`

Scope is optional but encouraged for multi-module repos. Keep subject under 50 chars, use imperative mood ("add" not "added"). Focus on the "why" not the "what".

### 5. Commit

**jj workflow (preferred)**:

```bash
jj status && jj diff --stat
jj describe -m "feat: message here"
```

**git workflow (fallback)**:

```bash
git add <specific-files>
git commit -F <scratchpad>/commit-msg.txt
```

Use the Write tool for commit message files (avoids shell escaping). Write them to the session scratchpad directory given in the environment context — not `/tmp`. There is no env var for it; substitute the literal path. Handle pre-commit hook failures by re-staging and retrying once.

### 6. Push (if --push or explicitly requested)

**PR-safety gate first.** If the branch already has an open PR, check for review activity before pushing anything that rewrites what's there:

```bash
gh pr view <branch> --json reviews,comments 2>/dev/null
```

Plain new commits on top are always safe. But if `reviews` or `comments` is non-empty and this push would rewrite already-pushed commits (amended description, squash, rebase), **stop and ask Teej** — force-pushing detaches review threads from their line anchors. See `rules/pr-safety.md`.

**jj**:

```bash
jj bookmark set <branch> -r @
jj git push --bookmark <branch>
```

**git**:

```bash
git push -u origin HEAD
```

### 7. Monitor CI (after push)

If `.github/workflows/` exists and `ci=github-actions` in hook output:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name>
```

**Do NOT pre-resolve the SHA and pass `--sha`.** The script resolves it from the bookmark/branch, which is correct under every workflow. Deriving it from `@-` is wrong whenever `@` *is* the pushed commit (the `jj describe -m` + `jj bookmark set -r @` flow used in step 6 above), and the failure is silent: the monitor watches the previous commit's finished run and a green predecessor reports a false pass. See `skills/monitoring-ci/SKILL.md`.

Run in background. Tell user: "CI monitor running in background."

## Error Handling

- Ask user about unknown project permissions
- Stop on protected branch violations
- Auto-fix code quality issues using detected formatters/linters
- Re-stage once if pre-commit hooks fail (git only)
- For jj: use `jj op restore` if something goes wrong

## Safety Rules

- Never commit to protected branches without permission
- Use temporary files for all commit message operations
- Stop on merge conflicts
- Check branch protection before making changes
