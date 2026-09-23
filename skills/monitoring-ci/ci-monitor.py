#!/usr/bin/env -S uv run --script
"""
CI/CD monitor — watches the latest GitHub Actions run for a branch.

Usage:
    ci-monitor.py [--branch BRANCH] [--sha SHA] [--timeout SECONDS] [--watch-timeout SECONDS]

Detects repo root via jj or git, finds the latest CI run for the branch,
and polls until completion. Exits 0 on success, 1 on failure, 2 when the
result is indeterminate (no run found, watch timeout, or gh API errors).
"""

import argparse
import json
import os
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


def sentinel_path(name: str, sha: str | None) -> Path:
    # Keyed by repo+sha so a monitor for one push never blocks a monitor for
    # the next push to the same repo; repo-level only when sha is unknown.
    suffix = f"-{sha[:12]}" if sha else ""
    return Path(f"/tmp/{name}-ci-monitor{suffix}")


def claim_sentinel(sentinel: Path, stale_after: int) -> bool:
    """Atomically claim the sentinel; True if claimed, False if another live monitor holds it.

    A sentinel older than stale_after is a leftover from a monitor that died
    without cleanup (SIGKILL skips the finally) — take it over.
    """
    try:
        age = time.time() - float(sentinel.read_text())
    except FileNotFoundError:
        age = None
    except ValueError:
        age = stale_after  # unreadable content — treat as stale
    if age is not None:
        if age < stale_after:
            return False
        sentinel.unlink(missing_ok=True)
    try:
        fd = os.open(sentinel, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        return False
    with os.fdopen(fd, "w") as f:
        f.write(str(time.time()))
    return True


def head_sha(branch: str) -> str | None:
    """Get the commit SHA that the branch currently points to."""
    # Resolve the branch/bookmark itself — NOT @/@-: in jj, @ is usually an
    # empty working-copy commit whose sha has no CI run.
    r = run(f"jj log -r '{branch}' --no-graph -T 'commit_id' 2>/dev/null")
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    r = run(f"git rev-parse {branch}")
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    return None


def find_runs(branch: str, max_wait: int = 180, expected_sha: str | None = None) -> list[str]:
    """Poll for CI runs on the branch matching expected_sha; return every run ID found.

    Skips runs with event `dynamic`: GitHub-managed workflows (Dependabot
    Updates, default CodeQL) attach to the same push and SHA, and watching one
    of those instead of the repo's own workflow reported a pass while the real
    check failed (2026-09-23). A push can start several workflows, so once one
    appears, re-list after a short pause to collect its siblings.

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

    found: list[str] = []
    settled = False
    for attempt in range(1, iterations + 1):
        r = run(
            "gh run list --limit 30 "
            "--json databaseId,status,headSha,headBranch,event --jq '.[]'"
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
            if data.get("headBranch", "") != branch or data.get("event") == "dynamic":
                continue
            branch_matches += 1
            run_sha = data.get("headSha", "")
            # Use prefix match so callers can pass short SHAs (the JSON from
            # `gh run list` always returns 40-char SHAs; a 12-char input would
            # never `==` match).
            if expected_sha and not run_sha.startswith(expected_sha):
                continue
            sha_matches += 1
            if run_id and run_id not in found:
                found.append(run_id)

        if found:
            if settled or attempt == iterations:
                return found
            # One more listing to pick up sibling workflows from the same push.
            settled = True
            time.sleep(poll_interval)
            continue

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
    return found


def watch_run(run_id: str, poll_interval: int = 10, timeout: int = 1800) -> int:
    """Poll a run's state until completion. Returns 0=success, 1=failure, 2=indeterminate.

    Replaces `gh run watch --exit-status`, which crashes hard on transient
    network errors (TCP resets are common over long watches) and doesn't
    distinguish a watch error from a run failure. With direct polling, a
    one-off API hiccup just delays detection by one poll interval instead of
    falsely reporting a CI failure. Tolerates up to ~1 min of consecutive API
    errors before giving up with 2 (indeterminate, NOT a CI failure).
    """
    deadline = time.time() + timeout
    consecutive_errors = 0
    while time.time() < deadline:
        r = run(f"gh run view {run_id} --json status,conclusion")
        if r.returncode != 0:
            consecutive_errors += 1
            if consecutive_errors * poll_interval > 60:
                print(f"  gh run view failing repeatedly: {r.stderr.strip()}")
                return 2
            time.sleep(poll_interval)
            continue
        consecutive_errors = 0
        try:
            data = json.loads(r.stdout)
        except json.JSONDecodeError:
            time.sleep(poll_interval)
            continue
        if data.get("status") == "completed":
            return 0 if data.get("conclusion") == "success" else 1
        time.sleep(poll_interval)
    return 2


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
    parser.add_argument(
        "--watch-timeout",
        type=int,
        default=1800,
        help=(
            "Max seconds to watch a found run (default: 1800). Callers that run "
            "this in a tool-call foreground must set this BELOW their own tool "
            "timeout, so the script exits with a real verdict."
        ),
    )
    args = parser.parse_args()

    name = repo_name()
    branch = args.branch or current_branch()

    if not branch:
        print("ERROR: Could not detect branch")
        return 1

    sha = args.sha or head_sha(branch)
    watch_timeout = args.watch_timeout
    sentinel = sentinel_path(name, sha)

    # Stale = older than the longest a healthy monitor can possibly live.
    if not claim_sentinel(sentinel, stale_after=args.timeout + watch_timeout + 120):
        print(f"CI monitor already active for {name} @ {sha[:12] if sha else branch}")
        return 0

    try:
        print(f"Watching CI for {name} @ {branch} (sha: {sha or 'unknown'}) ...")

        run_ids = find_runs(branch, max_wait=args.timeout, expected_sha=sha)
        if not run_ids:
            print(
                f"INDETERMINATE: no CI run found for {branch}"
                f"{f' @ {sha[:12]}' if sha else ''} after {args.timeout}s — "
                f"check manually: gh run list --limit 10"
            )
            return 2

        print(f"Found run(s) {', '.join(run_ids)} — watching ...")
        deadline = time.time() + watch_timeout
        results = {rid: watch_run(rid, timeout=max(1, int(deadline - time.time()))) for rid in run_ids}

        failed = [rid for rid, code in results.items() if code == 1]
        if failed:
            for rid in failed:
                print(f"\nCI FAILED (run {rid})\n")
                print(fetch_failed_logs(rid))
            return 1

        pending = [rid for rid, code in results.items() if code == 2]
        if pending:
            print(
                f"\nINDETERMINATE: run(s) {', '.join(pending)} still not complete — "
                f"check manually: gh run view {pending[0]}"
            )
            return 2

        print(f"\nCI PASSED (run(s) {', '.join(run_ids)})")
        return 0

    finally:
        sentinel.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
