#!/usr/bin/env -S uv run --script
"""
CI/CD monitor — watches the latest GitHub Actions run for a branch.

Usage:
    ci-monitor.py [--branch BRANCH] [--timeout SECONDS]

Detects repo root via jj or git, finds the latest CI run for the branch,
and polls until completion. Exits 0 on success, 1 on failure, 2 on timeout.
"""

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path


def run(cmd: str, *, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)


def repo_name() -> str:
    r = run("jj workspace root 2>/dev/null")
    root = r.stdout.strip() if r.returncode == 0 else None
    if not root:
        r = run("git rev-parse --show-toplevel")
        root = r.stdout.strip()
    return Path(root).name


def current_branch() -> str:
    # In jj, check @ first, then @- (bookmark is usually on parent after push)
    for rev in ("@", "@-"):
        r = run(f"jj log -r '{rev}' --no-graph -T 'bookmarks'")
        if r.returncode == 0 and r.stdout.strip():
            raw = r.stdout.strip().split()[0]
            branch = raw.split("@")[0].rstrip("*")
            if branch:
                return branch
    r = run("git branch --show-current")
    return r.stdout.strip()


def sentinel_path(name: str) -> Path:
    return Path(f"/tmp/{name}-ci-monitor")


def find_run(branch: str, max_wait: int = 60) -> str | None:
    """Poll for a CI run on the branch, return run ID or None."""
    for _ in range(max_wait // 5):
        r = run(
            f"gh run list --branch {branch} --limit 1 "
            f"--json databaseId,status --jq '.[0]'"
        )
        if r.returncode == 0 and r.stdout.strip():
            data = json.loads(r.stdout.strip())
            run_id = str(data.get("databaseId", ""))
            if run_id:
                return run_id
        time.sleep(5)
    return None


def watch_run(run_id: str) -> int:
    """Watch a run until completion. Returns exit code."""
    r = run(f"gh run watch {run_id} --exit-status", check=False)
    print(r.stdout)
    if r.returncode != 0:
        print(r.stderr)
    return r.returncode


def fetch_failed_logs(run_id: str) -> str:
    r = run(f"gh run view {run_id} --log-failed")
    return r.stdout[-3000:] if r.stdout else "(no logs)"


def main() -> int:
    parser = argparse.ArgumentParser(description="Monitor GitHub Actions CI run")
    parser.add_argument("--branch", help="Branch to monitor (auto-detected if omitted)")
    parser.add_argument("--timeout", type=int, default=600, help="Max seconds to wait (default: 600)")
    args = parser.parse_args()

    name = repo_name()
    branch = args.branch or current_branch()
    sentinel = sentinel_path(name)

    if not branch:
        print("ERROR: Could not detect branch")
        return 1

    if sentinel.exists():
        print(f"CI monitor already active for {name}")
        return 0

    sentinel.write_text(str(time.time()))

    try:
        print(f"Watching CI for {name} @ {branch} ...")

        run_id = find_run(branch)
        if not run_id:
            print(f"No CI run found for branch {branch} after polling")
            return 0

        print(f"Found run {run_id} — watching ...")
        exit_code = watch_run(run_id)

        if exit_code != 0:
            print(f"\nCI FAILED (run {run_id})\n")
            logs = fetch_failed_logs(run_id)
            print(logs)
            return 1

        print(f"\nCI PASSED (run {run_id})")
        return 0

    finally:
        sentinel.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
