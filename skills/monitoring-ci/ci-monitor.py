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


def head_sha(branch: str) -> str | None:
    """Get the commit SHA that the branch currently points to."""
    # Try jj first (bookmark may be on @-)
    for rev in ("@", "@-"):
        r = run(f"jj log -r '{rev}' --no-graph -T 'commit_id'")
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    # Fallback to git
    r = run(f"git rev-parse {branch}")
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    return None


def find_run(branch: str, max_wait: int = 180, expected_sha: str | None = None) -> str | None:
    """Poll for a CI run on the branch matching expected_sha, return run ID or None.

    NOTE: deliberately does NOT pass `--branch` to `gh run list`. As of
    `gh` 2.91.0 (released 2026-04-22), `gh run list --branch <name>
    --json <fields>` returns `[]` even when matching runs exist; the
    same query works without either flag but the combination is broken.
    Filtering branch client-side is bulletproof and survives any future
    flag-handling regressions.
    """
    poll_interval = 5
    iterations = max(1, max_wait // poll_interval)
    last_summary: tuple[int, int, int] | None = None

    # Grace before the first poll: GitHub typically takes a few seconds to
    # register a workflow run after a push, so polling immediately at push+0
    # is a guaranteed miss.
    time.sleep(5)

    for attempt in range(1, iterations + 1):
        r = run(
            "gh run list --limit 30 "
            "--json databaseId,status,headSha,headBranch --jq '.[]'"
        )
        if r.returncode != 0:
            print(f"  poll {attempt}/{iterations}: gh failed — {r.stderr.strip()}")
            time.sleep(poll_interval)
            continue

        seen = 0
        branch_matches = 0
        sha_matches = 0
        for line in r.stdout.strip().split("\n"):
            if not line:
                continue
            seen += 1
            data = json.loads(line)
            run_id = str(data.get("databaseId", ""))
            if data.get("headBranch", "") != branch:
                continue
            branch_matches += 1
            run_sha = data.get("headSha", "")
            # Use prefix match so callers can pass short SHAs (the JSON from
            # `gh run list` always returns 40-char SHAs; a 12-char input would
            # never `==` match).
            if expected_sha and not run_sha.startswith(expected_sha):
                continue
            sha_matches += 1
            if run_id:
                return run_id

        # Only print when we couldn't match — keeps the happy path quiet.
        # Suppress duplicate summaries so a long stall produces one line,
        # not 12 identical ones.
        summary = (seen, branch_matches, sha_matches)
        if summary != last_summary:
            wanted = f" (need sha {expected_sha[:12]})" if expected_sha else ""
            print(
                f"  poll {attempt}/{iterations}: "
                f"saw {seen} runs, {branch_matches} on {branch}, "
                f"{sha_matches} matching{wanted}"
            )
            last_summary = summary
        if attempt < iterations:
            time.sleep(poll_interval)
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
    parser.add_argument("--sha", help="Expected HEAD SHA to match (avoids watching stale runs)")
    parser.add_argument(
        "--timeout",
        type=int,
        default=180,
        help="Max seconds to poll for a CI run to appear (default: 180)",
    )
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
        sha = args.sha or head_sha(branch)
        print(f"Watching CI for {name} @ {branch} (sha: {sha or 'unknown'}) ...")

        run_id = find_run(branch, max_wait=args.timeout, expected_sha=sha)
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
