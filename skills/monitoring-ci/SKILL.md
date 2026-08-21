---
name: monitoring-ci
description: Monitor and watch GitHub Actions CI/CD pipeline runs in real time. Use when the user has pushed code and wants to watch the build, check CI status, see if tests passed, monitor a pipeline, or wait for a workflow run to complete. Also use after any `jj git push` or `git push` command. Reports pass/fail with failed job logs. Do NOT use for writing or editing CI workflow YAML files, optimizing CI config, or debugging CI configuration — only for monitoring active runs.
when_to_use: "Typed as 'did CI pass', 'is it green', 'watch the build', 'check the run', or immediately after a push lands. Not for authoring or debugging workflow YAML."
context: fork
model: claude-sonnet-5
effort: low
disallowed-tools: AskUserQuestion
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

Run the script after pushing:

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
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name> --watch-timeout 480
```

**Run it in the FOREGROUND — do not pass `run_in_background` — and pass
`timeout: 600000` on the Bash call.**

`--watch-timeout 480` and `timeout: 600000` are a matched pair, and both are
required. The script's own default watch budget is 1800s, which is longer than
the Bash tool can ever wait: when the tool timeout expires first, Bash moves the
command to the background, this fork's turn ends immediately, and its completion
notification carries "monitor running" instead of a verdict — the same
verdict-reaches-nobody failure as backgrounding it deliberately, arrived at by a
different route. Observed 2026-08-21: a green run was reported as merely
"running" and had to be recovered by hand with `gh run list`.

Bounding the script at 480s keeps it inside the 600s tool ceiling, so it always
exits with a real code of its own — `2` if CI genuinely outran the budget, which
is honest and actionable, rather than silence.

**If Bash reports the command was moved to the background anyway, do NOT end
your turn.** That message names an output file. Read it, and keep reading until
the script's final verdict line appears, then report that. Ending the turn on
"moved to the background" is the bug this section exists to prevent.

This skill is `context: fork` at the default `background: true`, so it is already
detached from the user's conversation. The script blocking *here* costs them
nothing, and the fork's own completion notification is what carries the verdict
back.

Backgrounding the script inside the fork breaks exactly that. The fork's turn
ends the instant the command is launched, so its notification fires seconds later
carrying only "monitor running", while the real monitor keeps running inside a
session that no longer exists — its output file is never read and the pass/fail
reaches nobody. Observed 2026-08-17: a push was reported as monitored when
nothing was watching it, and the status had to be recovered by hand with
`gh run list`.

Report the script's actual verdict when it exits: `0` pass, `1` fail (include the
failing logs it printed), `2` indeterminate — **not** a pass, so pass along the
manual-check command from its output.

`run_in_background: true` is correct only when the monitor is launched from the
main conversation instead of from this skill — `committing-changes` step 7 does
this — because that session stays alive to receive the notification.

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
