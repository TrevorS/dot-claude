#!/usr/bin/env python3
"""Test context injection auto-loading for skills.

Tests whether Claude correctly loads skills when hook context is injected
via system-reminder (e.g., vcs=jj-colocated triggers using-jj).

Unlike run_eval.py which tests description matching, this tests the
CLAUDE.md AUTO-LOAD instruction path:
  hook fires → system-reminder contains context → CLAUDE.md says load skill → Claude loads it

Usage:
    python evals/context-injection-eval.py --verbose
    python evals/context-injection-eval.py --skill using-jj
    python evals/context-injection-eval.py --timeout 45
"""

import argparse
import json
import os
import select
import subprocess
import sys
import tempfile
import time
from pathlib import Path

# Each test case specifies:
#   - query: what to ask Claude
#   - cwd: where to run (determines hook output)
#   - expected_skill: which skill should be loaded (or None for no skill)
#   - setup: optional shell commands to create the test environment
#   - cleanup: optional shell commands to tear down

EVAL_CASES = [
    # === using-jj: should load in jj-colocated repos ===
    {
        "name": "jj-colocated-absorb-conflicts",
        "query": "I have conflicts from a rebase, help me resolve them and then absorb my fixups into the right commits",
        "expected_skill": "using-jj",
        "repo_type": "jj-colocated",
        "description": "Complex jj conflict resolution + absorb in jj-colocated repo should auto-load using-jj",
    },
    {
        "name": "jj-colocated-describe-change",
        "query": "describe my current change as 'fix: update config'",
        "expected_skill": "using-jj",
        "repo_type": "jj-colocated",
        "description": "jj-specific action in jj-colocated repo",
    },
    {
        "name": "jj-colocated-rebase-stack",
        "query": "rebase my current stack of changes onto main and squash the fixup commits",
        "expected_skill": "using-jj",
        "repo_type": "jj-colocated",
        "description": "Complex jj operation in jj-colocated repo should auto-load using-jj",
    },
    # === using-git: should load in git-only repos ===
    {
        "name": "git-only-interactive-rebase",
        "query": "I need to squash the last 5 commits on this feature branch and reword them before opening a PR",
        "expected_skill": "using-git",
        "repo_type": "git-only",
        "description": "Complex git rebase in git-only repo should auto-load using-git",
    },
    {
        "name": "git-only-commit-prompt",
        "query": "squash the last 3 commits into one",
        "expected_skill": "using-git",
        "repo_type": "git-only",
        "description": "Git action in git-only repo should load using-git, not using-jj",
    },
    # === Negative cases: jj skill should NOT load in git-only repos ===
    {
        "name": "git-only-no-jj",
        "query": "show me the diff of my working copy",
        "expected_not_skill": "using-jj",
        "repo_type": "git-only",
        "description": "using-jj should NOT load in git-only repos",
    },
    # === monitoring-ci: should load after push context ===
    {
        "name": "ci-after-push-context",
        "query": "I just pushed, watch the CI",
        "expected_skill": "monitoring-ci",
        "repo_type": "git-only",
        "description": "CI monitoring should trigger after push-related prompts in CI-enabled repos",
    },
]


def create_test_repo(repo_type: str, base_dir: str) -> str:
    """Create a temporary repo of the specified type."""
    repo_dir = os.path.join(base_dir, f"test-{repo_type}")
    os.makedirs(repo_dir, exist_ok=True)

    if repo_type == "jj-colocated":
        subprocess.run(["git", "init"], cwd=repo_dir, capture_output=True)
        subprocess.run(["jj", "git", "init", "--colocate"], cwd=repo_dir, capture_output=True)
        # Create a file so there's something to work with
        Path(repo_dir, "README.md").write_text("# Test Project\n")
        subprocess.run(["jj", "describe", "-m", "init"], cwd=repo_dir, capture_output=True)
    elif repo_type == "git-only":
        subprocess.run(["git", "init"], cwd=repo_dir, capture_output=True)
        Path(repo_dir, "README.md").write_text("# Test Project\n")
        subprocess.run(["git", "add", "."], cwd=repo_dir, capture_output=True)
        subprocess.run(
            ["git", "commit", "-m", "init", "--allow-empty"],
            cwd=repo_dir,
            capture_output=True,
            env={**os.environ, "GIT_AUTHOR_NAME": "test", "GIT_AUTHOR_EMAIL": "test@test.com",
                 "GIT_COMMITTER_NAME": "test", "GIT_COMMITTER_EMAIL": "test@test.com"},
        )

    # Copy the user's CLAUDE.md so AUTO-LOAD instructions are present
    claude_dir = os.path.join(repo_dir, ".claude")
    os.makedirs(claude_dir, exist_ok=True)
    user_claude_md = Path.home() / ".claude" / "CLAUDE.md"
    if user_claude_md.exists():
        Path(claude_dir, "CLAUDE.md").write_text(user_claude_md.read_text())

    return repo_dir


def run_test_case(
    case: dict,
    repo_dirs: dict[str, str],
    timeout: int,
) -> dict:
    """Run a single context injection test case."""
    repo_dir = repo_dirs[case["repo_type"]]
    query = case["query"]
    expected_skill = case.get("expected_skill")
    expected_not_skill = case.get("expected_not_skill")

    cmd = [
        "claude", "-p", query,
        "--output-format", "stream-json",
        "--verbose",
        "--include-partial-messages",
    ]

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        cwd=repo_dir,
        env=env,
    )

    skill_loads = set()
    start_time = time.time()
    buffer = ""
    pending_tool_name = None
    accumulated_json = ""

    try:
        while time.time() - start_time < timeout:
            if process.poll() is not None:
                remaining = process.stdout.read()
                if remaining:
                    buffer += remaining.decode("utf-8", errors="replace")
                break

            ready, _, _ = select.select([process.stdout], [], [], 1.0)
            if not ready:
                continue

            chunk = os.read(process.stdout.fileno(), 8192)
            if not chunk:
                break
            buffer += chunk.decode("utf-8", errors="replace")

            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue

                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                # Detect Skill tool calls
                if event.get("type") == "assistant":
                    message = event.get("message", {})
                    for content_item in message.get("content", []):
                        if content_item.get("type") != "tool_use":
                            continue
                        tool_name = content_item.get("name", "")
                        tool_input = content_item.get("input", {})
                        if tool_name == "Skill":
                            skill_loads.add(tool_input.get("skill", ""))

                # Also check stream events for early detection
                if event.get("type") == "stream_event":
                    se = event.get("event", {})
                    if se.get("type") == "content_block_start":
                        cb = se.get("content_block", {})
                        if cb.get("type") == "tool_use" and cb.get("name") == "Skill":
                            pending_tool_name = "Skill"
                            accumulated_json = ""
                    elif se.get("type") == "content_block_delta" and pending_tool_name == "Skill":
                        delta = se.get("delta", {})
                        if delta.get("type") == "input_json_delta":
                            accumulated_json += delta.get("partial_json", "")
                    elif se.get("type") == "content_block_stop" and pending_tool_name == "Skill":
                        try:
                            skill_input = json.loads(accumulated_json)
                            skill_loads.add(skill_input.get("skill", ""))
                        except json.JSONDecodeError:
                            pass
                        pending_tool_name = None
                        accumulated_json = ""
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()

    # Evaluate pass/fail
    passed = False
    reason = ""
    if expected_skill:
        if expected_skill in skill_loads:
            passed = True
            reason = f"correctly loaded {expected_skill}"
        else:
            reason = f"expected {expected_skill}, got {skill_loads or 'nothing'}"
    elif expected_not_skill:
        if expected_not_skill not in skill_loads:
            passed = True
            reason = f"correctly did NOT load {expected_not_skill}"
        else:
            reason = f"unexpectedly loaded {expected_not_skill}"

    return {
        "name": case["name"],
        "description": case["description"],
        "passed": passed,
        "reason": reason,
        "skill_loads": list(skill_loads),
        "elapsed": round(time.time() - start_time, 1),
    }


def main():
    parser = argparse.ArgumentParser(description="Test context injection auto-loading")
    parser.add_argument("--skill", help="Only run tests for this skill")
    parser.add_argument("--timeout", type=int, default=60, help="Timeout per test in seconds")
    parser.add_argument("--verbose", action="store_true", help="Print progress")
    parser.add_argument("--case", help="Run a specific test case by name")
    args = parser.parse_args()

    cases = EVAL_CASES
    if args.skill:
        cases = [c for c in cases if c.get("expected_skill") == args.skill or c.get("expected_not_skill") == args.skill]
    if args.case:
        cases = [c for c in cases if c["name"] == args.case]

    if not cases:
        print("No matching test cases found.", file=sys.stderr)
        sys.exit(1)

    # Create test repos
    repo_types = set(c["repo_type"] for c in cases)
    with tempfile.TemporaryDirectory(prefix="ctx-eval-") as tmpdir:
        if args.verbose:
            print(f"Creating test repos in {tmpdir}", file=sys.stderr)

        repo_dirs = {}
        for rt in repo_types:
            repo_dirs[rt] = create_test_repo(rt, tmpdir)
            if args.verbose:
                print(f"  Created {rt} repo at {repo_dirs[rt]}", file=sys.stderr)

        # Run tests
        results = []
        for i, case in enumerate(cases):
            if args.verbose:
                print(f"\n[{i+1}/{len(cases)}] {case['name']}: {case['query'][:60]}...", file=sys.stderr)

            result = run_test_case(case, repo_dirs, args.timeout)
            results.append(result)

            status = "PASS" if result["passed"] else "FAIL"
            if args.verbose:
                print(f"  [{status}] {result['reason']} ({result['elapsed']}s)", file=sys.stderr)

    # Summary
    passed = sum(1 for r in results if r["passed"])
    total = len(results)
    print(f"\nResults: {passed}/{total} passed", file=sys.stderr)

    output = {
        "summary": {"passed": passed, "failed": total - passed, "total": total},
        "results": results,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
