# CI Monitoring: Watch the Build Without Being Asked

After a push lands, launching the CI monitor is the **default action, not a
question**. Do not ask "want me to watch CI?" — start it and say that you did.

## When to launch

Launch immediately when all three hold:

1. A push just succeeded (`jj git push`, `git push`, or the push step of
   `committing-changes`).
2. `ci=github-actions` in the `UserPromptSubmit` hook context, or
   `.github/workflows/` exists in the repo.
3. `gh` is authenticated.

`ci-monitor.py` drives the `gh` CLI, so GitHub Actions is the only CI it can
watch. `ci=gitlab` and `ci=circleci` are **not** available for these purposes —
say CI isn't monitorable and move on rather than launching a watcher that will
find nothing.

## How to launch

From the main conversation, one Bash call, `run_in_background: true`:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name>
```

Already covered by the `Bash(uv run ~/.claude/skills/monitoring-ci/ci-monitor.py:*)`
allow rule, so it will not prompt.

Do **not** pre-resolve the SHA. Do **not** background it when running inside the
`monitoring-ci` fork — the rules differ by caller and both failure modes are
documented in `skills/monitoring-ci/SKILL.md`. Read that skill before changing
how it is invoked.

## Reporting

Say one line at launch ("CI monitor running in background"), then report the
real verdict when the completion notification arrives: `0` pass, `1` fail with
the failing logs, `2` indeterminate — which is **not** a pass, so pass along the
manual-check command.

## Still ask first when

- The push itself failed or was blocked by a hook.
- The task was explicitly local-only ("just commit, don't push").
- Teej already declined a monitor for this same push.

A standing "don't watch CI" from Teej holds for the rest of the session.

## Not for

- Re-running a monitor for a push that already has one — the script
  deduplicates per SHA, but a second launch is still noise.
- Watching CI on someone else's branch or an unrelated PR without being asked.
- Authoring or debugging workflow YAML — that is not monitoring.
