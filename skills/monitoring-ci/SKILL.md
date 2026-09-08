---
name: monitoring-ci
description: Watch a GitHub Actions run after a push and report pass/fail with the failing job logs. Use after any `jj git push` or `git push`, or when the user asks whether CI passed. Not for writing or debugging workflow YAML.
when_to_use: "Typed as 'did CI pass', 'is it green', 'watch the build', 'check the run', or immediately after a push lands. Not for authoring or debugging workflow YAML."
context: fork
model: sonnet
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

This skill is strictly read-only: run `ci-monitor.py` and report its result. Do not edit `ci-monitor.py`, this file, or any other file, and do not commit or push. If you can't extract a branch or SHA from the arguments, run the script with no flags (it auto-detects) and say so in your report.

## How to Invoke

After a push, pass the branch and let the script resolve the SHA:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name> --watch-timeout 480
```

**Run it in the FOREGROUND — do not pass `run_in_background` — and pass
`timeout: 600000` on the Bash call.**

The two timeouts are a matched pair. The script's default watch budget (1800s)
outlasts the Bash tool ceiling; when the tool timeout expires first, Bash moves
the command to the background, this fork's turn ends, and the notification
carries "monitor running" instead of a verdict (observed 2026-08-21). Bounding
the script at 480s keeps it inside 600s so it always exits with a real code.

This fork is what carries the verdict back, so the script must block *here*.
Backgrounding it inside the fork ends the turn the instant the command launches;
the monitor keeps running in a session that no longer exists and the pass/fail
reaches nobody (observed 2026-08-17). `run_in_background: true` is correct only
from the main conversation, which stays alive for the notification.

**If Bash reports the command was moved to the background anyway, do not end
your turn.** Read the output file it names until the final verdict line appears,
then report that.

## SHA resolution (canonical explanation)

Do not pre-resolve the SHA. The script resolves it from the bookmark/branch
(`sha = args.sha or head_sha(branch)`), which is correct under every workflow.
Never derive it from `@-`: that is the parent of the working copy, which is only
the pushed commit in the flow where `@` is a fresh empty change on top. In the
`jj describe @` + `jj bookmark set -r @` flow the pushed commit **is** `@`, so
`@-` is the commit before it. The failure is silent: the monitor watches the
previous commit's finished run and a green predecessor yields a false pass.
Pass `--sha` only when a SHA was given explicitly on the `ARGUMENTS:` line.

## Script behaviour worth knowing

- Deduplicates per push via a sentinel at `/tmp/{repo}-ci-monitor-{sha12}`; a second monitor for the same push exits `0` with "already active", and stale sentinels are taken over.
- Waits up to 180s for a run to appear (`--timeout`), then polls every 10s; a transient API error delays one poll instead of crashing.

## Exit Codes

- `0` — CI passed (or another monitor already active for this push)
- `1` — CI failed (logs printed)
- `2` — indeterminate: no run found, watch timed out, or gh API kept erroring. NOT a pass — report the manual-check command from the output.
