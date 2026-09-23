---
name: monitoring-ci
description: Watch a GitHub Actions run and report pass/fail with the failing job logs when the user asks whether CI passed. Post-push monitoring without being asked is rules/ci-monitoring.md, not this skill. Not for writing or debugging workflow YAML.
when_to_use: "Typed as 'did CI pass', 'is it green', 'watch the build', or 'check the run'."
context: fork
model: sonnet
effort: low
disallowed-tools: AskUserQuestion
---

# CI Monitor

Watch GitHub Actions CI runs after a push.

## Interpreting skill arguments

Anything on the `ARGUMENTS:` line is a set of monitoring parameters, never a task description. Pick out the branch name and/or hex commit SHA and pass them as `--branch` / `--sha`; ignore filler words like "push", "commit", or "monitor".

This skill is read-only: run `ci-monitor.py` and report its result. If you can't extract a branch or SHA from the arguments, run the script with no flags (it auto-detects) and say so in your report.

## How to Invoke

After a push, pass the branch and let the script resolve the SHA:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name> --watch-timeout 480
```

**Run it in the FOREGROUND — do not pass `run_in_background` — and pass
`timeout: 600000` on the Bash call.**

The two timeouts are a matched pair. A foreground command that hits its tool
timeout is auto-backgrounded, so the watch budget must sit under the 600s
ceiling. Bounding the script at 480s keeps it inside 600s so it always exits
with a real code.

If Bash backgrounds it anyway, report the verdict from the completion, never
"monitor running".

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
