# CI Monitoring: Watch the Build Without Being Asked

After a push lands, launching the CI monitor is the default action, not a question. Launch it when the push succeeded, the repo uses GitHub Actions (`ci=github-actions` in the prompt context, or `.github/workflows/` exists), and `gh` is authenticated. `ci-monitor.py` drives `gh`, so GitLab and CircleCI are not monitorable; say so and move on.

From the main conversation, one Bash call with `run_in_background: true`:

```bash
uv run ~/.claude/skills/monitoring-ci/ci-monitor.py --branch <branch-name>
```

Do not pre-resolve the SHA; the script does it. The `monitoring-ci` skill holds the foreground/background rules for its own fork.

Say one line at launch ("CI monitor running in background"), then report the real verdict when the completion notification arrives: `0` pass, `1` fail with the failing logs, `2` indeterminate, which is **not** a pass, so pass along the manual-check command.

Ask first only when the push failed or was blocked, the task was explicitly local-only, or Teej already declined a monitor for this push. A standing "don't watch CI" holds for the rest of the session.
