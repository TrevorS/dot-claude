---
name: monitoring-ci
description: Monitor and watch GitHub Actions CI/CD pipeline runs in real time. Use when the user has pushed code and wants to watch the build, check CI status, see if tests passed, monitor a pipeline, or wait for a workflow run to complete. Also use after any `jj git push` or `git push` command. Reports pass/fail with failed job logs. Do NOT use for writing or editing CI workflow YAML files, optimizing CI config, or debugging CI configuration — only for monitoring active runs.
context: fork
model: claude-sonnet-4-6
---

# CI Monitor

Watch GitHub Actions CI runs after a push. Auto-detects repo and branch, deduplicates concurrent monitors, reports results.

## Interpreting skill arguments

Anything on the `ARGUMENTS:` line is a set of monitoring parameters, never a task description. Pick out the branch name and/or hex commit SHA and pass them as `--branch` / `--sha`; ignore filler words like "push", "commit", or "monitor". For example, `ARGUMENTS: master push 0bed725ba7cb` means:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch master --sha 0bed725ba7cb
```

This skill is strictly read-only: run `ci-monitor.py` and report its result. Do NOT edit `ci-monitor.py`, this file, or any other file; do NOT commit, push, or change the script's interface — even if the arguments look like they don't match the script's flags. If you can't extract a branch or SHA from the arguments, run the script with no flags (it auto-detects) and say so in your report.

## Usage

Run the script in the background after pushing:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py
```

With explicit branch:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch my-feature
```

## How to Invoke from Claude

After a push, pass the branch and let the script resolve the SHA:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name>
```

Use `run_in_background: true` so it doesn't block the conversation. Tell the user: "CI monitor running in background — you'll be notified when it completes."

**Do NOT pre-resolve the SHA yourself.** The script already resolves it from the bookmark/branch (`sha = args.sha or head_sha(branch)`), which is correct under every workflow. Passing a hand-computed `--sha` only overrides that with something more likely to be wrong.

In particular, never derive it from `@-`. That is the *parent* of the working copy, which is only the pushed commit in the git-style flow where `@` is a fresh empty change on top. In the `jj describe @` + `jj bookmark move --to @` flow the pushed commit **is** `@`, so `@-` resolves to the commit before it. The failure is silent and dangerous: the monitor watches the previous commit's already-finished run and reports *its* conclusion, so a green predecessor yields a false pass on unverified work.

Pass `--sha` only when a SHA was given explicitly on the `ARGUMENTS:` line.

## Features

- **Auto-detects branch**: jj bookmarks first, falls back to git
- **Deduplicates per push**: sentinel at `/tmp/{repo}-ci-monitor-{sha12}` prevents double-watching the *same* push, while monitors for different pushes coexist; stale sentinels (dead monitor) are taken over automatically
- **Polls for run**: waits up to 180s for a CI run to appear on the branch (configurable via `--timeout`); sleeps 5s first so GitHub has time to register the run
- **Watches until done**: polls `gh run view --json status,conclusion` every 10s — a transient API error delays detection by one poll instead of crashing the watcher (which is what `gh run watch` does on a TCP reset)
- **Reports failure logs**: on failure, fetches `gh run view --log-failed` (last 3000 chars)
- **Cleans up**: always removes sentinel, even on error

## Exit Codes

- `0` — CI passed (or another monitor already active for this push)
- `1` — CI failed (logs printed)
- `2` — indeterminate: no run found, watch timed out, or gh API kept erroring. NOT a pass — report the manual-check command from the output.

## Requirements

- `gh` CLI authenticated
- GitHub Actions workflows in the repo
