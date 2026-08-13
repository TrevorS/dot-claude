#!/usr/bin/env python3
"""Quality eval for committing-changes skill.

Creates test repos with staged changes, invokes Claude to generate commit
messages, then grades them against quality criteria.

Usage:
    python skills/committing-changes/evals/quality-eval.py --verbose
    python skills/committing-changes/evals/quality-eval.py --case bug-fix
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCENARIOS = [
    {
        "name": "simple-bug-fix",
        "description": "Single file bug fix — off-by-one error in loop",
        "files": {
            "src/utils.py": {
                "before": 'def paginate(items, page_size):\n    """Split items into pages."""\n    pages = []\n    for i in range(0, len(items), page_size):\n        pages.append(items[i:i + page_size - 1])\n    return pages\n',
                "after": 'def paginate(items, page_size):\n    """Split items into pages."""\n    pages = []\n    for i in range(0, len(items), page_size):\n        pages.append(items[i:i + page_size])\n    return pages\n',
            }
        },
        "prompt": "commit this fix",
        "assertions": {
            "type_prefix": "should start with fix: or fix(scope):",
            "mentions_bug": "should reference the off-by-one or pagination bug",
            "under_72_chars": "subject line should be under 72 characters",
            "no_obvious_filler": "should not contain generic filler like 'update code' or 'fix bug'",
        },
    },
    {
        "name": "new-feature",
        "description": "Add a new API endpoint with handler and route",
        "files": {
            "src/routes.py": {
                "before": 'from flask import Blueprint\n\napi = Blueprint("api", __name__)\n\n@api.route("/users")\ndef list_users():\n    return {"users": []}\n',
                "after": 'from flask import Blueprint, request\n\napi = Blueprint("api", __name__)\n\n@api.route("/users")\ndef list_users():\n    return {"users": []}\n\n@api.route("/users/<int:user_id>/settings", methods=["GET", "PUT"])\ndef user_settings(user_id):\n    if request.method == "PUT":\n        return {"updated": True}\n    return {"settings": {}}\n',
            }
        },
        "prompt": "commit these changes",
        "assertions": {
            "type_prefix": "should start with feat: or feat(scope):",
            "mentions_endpoint": "should reference user settings or API endpoint",
            "under_72_chars": "subject line should be under 72 characters",
            "action_verb": "should use an action verb (add, implement, create)",
        },
    },
    {
        "name": "multi-file-refactor",
        "description": "Rename a function across multiple files",
        "files": {
            "src/auth.py": {
                "before": 'def check_auth(token):\n    """Validate auth token."""\n    return token == "valid"\n',
                "after": 'def validate_token(token):\n    """Validate auth token."""\n    return token == "valid"\n',
            },
            "src/middleware.py": {
                "before": 'from auth import check_auth\n\ndef auth_middleware(request):\n    return check_auth(request.token)\n',
                "after": 'from auth import validate_token\n\ndef auth_middleware(request):\n    return validate_token(request.token)\n',
            },
            "tests/test_auth.py": {
                "before": 'from auth import check_auth\n\ndef test_auth():\n    assert check_auth("valid")\n    assert not check_auth("invalid")\n',
                "after": 'from auth import validate_token\n\ndef test_auth():\n    assert validate_token("valid")\n    assert not validate_token("invalid")\n',
            },
        },
        "prompt": "commit this refactor",
        "assertions": {
            "type_prefix": "should start with refactor: or refactor(scope):",
            "mentions_rename": "should reference renaming check_auth to validate_token",
            "under_72_chars": "subject line should be under 72 characters",
        },
    },
    {
        "name": "config-change",
        "description": "Update CI config to add a new test matrix entry",
        "files": {
            ".github/workflows/ci.yml": {
                "before": 'name: CI\non: [push]\njobs:\n  test:\n    strategy:\n      matrix:\n        node: [18, 20]\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n        with:\n          node-version: ${{ matrix.node }}\n      - run: npm test\n',
                "after": 'name: CI\non: [push]\njobs:\n  test:\n    strategy:\n      matrix:\n        node: [18, 20, 22]\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n        with:\n          node-version: ${{ matrix.node }}\n      - run: npm test\n',
            }
        },
        "prompt": "commit",
        "assertions": {
            "type_prefix": "should start with ci: or chore: or build:",
            "mentions_node": "should reference Node 22 or test matrix",
            "under_72_chars": "subject line should be under 72 characters",
            "concise": "subject line should be under 50 characters ideally",
        },
    },
]


def create_test_repo(scenario: dict, base_dir: str) -> str:
    """Create a git repo with the scenario's changes staged."""
    repo_dir = os.path.join(base_dir, scenario["name"])
    os.makedirs(repo_dir, exist_ok=True)

    env = {
        **os.environ,
        "GIT_AUTHOR_NAME": "test",
        "GIT_AUTHOR_EMAIL": "test@test.com",
        "GIT_COMMITTER_NAME": "test",
        "GIT_COMMITTER_EMAIL": "test@test.com",
    }

    subprocess.run(["git", "init"], cwd=repo_dir, capture_output=True, env=env)
    # Disable hooks in test repo
    subprocess.run(["git", "config", "core.hooksPath", "/dev/null"], cwd=repo_dir, capture_output=True, env=env)

    # Write "before" state and commit
    for filepath, content in scenario["files"].items():
        full_path = os.path.join(repo_dir, filepath)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        Path(full_path).write_text(content["before"])

    subprocess.run(["git", "add", "."], cwd=repo_dir, capture_output=True, env=env)
    subprocess.run(
        ["git", "commit", "-m", "initial commit"],
        cwd=repo_dir, capture_output=True, env=env,
    )

    # Write "after" state and stage
    for filepath, content in scenario["files"].items():
        full_path = os.path.join(repo_dir, filepath)
        Path(full_path).write_text(content["after"])

    subprocess.run(["git", "add", "."], cwd=repo_dir, capture_output=True, env=env)

    # Add a minimal CLAUDE.md with direct-commits-allowed
    claude_dir = os.path.join(repo_dir, ".claude")
    os.makedirs(claude_dir, exist_ok=True)
    Path(os.path.join(repo_dir, "CLAUDE.md")).write_text(
        "# Test Project\n\ndirect-commits-allowed: true\n\n"
        "## Commits\n\n"
        "Use conventional commits format: type(scope): description\n"
        "Valid types: feat, fix, refactor, docs, style, perf, test, build, ci, chore.\n"
    )

    return repo_dir


def run_commit_eval(
    scenario: dict,
    repo_dir: str,
    timeout: int,
) -> dict:
    """Run claude -p with the commit prompt and extract the commit message."""
    prompt = scenario["prompt"]

    cmd = [
        "claude", "-p", prompt,
        "--output-format", "stream-json",
        "--verbose",
    ]

    env_clean = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        cwd=repo_dir,
        env=env_clean,
    )

    buffer = ""
    result_text = ""
    start_time = time.time()

    try:
        while time.time() - start_time < timeout:
            if process.poll() is not None:
                remaining = process.stdout.read()
                if remaining:
                    buffer += remaining.decode("utf-8", errors="replace")
                break

            chunk = process.stdout.read(8192)
            if not chunk:
                break
            buffer += chunk.decode("utf-8", errors="replace")

        # Parse the result
        for line in buffer.split("\n"):
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
                if event.get("type") == "result":
                    result_text = event.get("result", "")
            except json.JSONDecodeError:
                continue
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()

    # Extract commit message from git log
    r = subprocess.run(
        ["git", "log", "-1", "--format=%s%n%n%b"],
        cwd=repo_dir, capture_output=True, text=True,
    )
    commit_msg = r.stdout.strip() if r.returncode == 0 else ""

    # Check if a commit was actually made
    r2 = subprocess.run(
        ["git", "log", "--oneline", "-2"],
        cwd=repo_dir, capture_output=True, text=True,
    )
    committed = r2.stdout.strip().count("\n") >= 1  # More than just initial commit

    elapsed = round(time.time() - start_time, 1)

    return {
        "committed": committed,
        "commit_message": commit_msg,
        "claude_output": result_text[:500],
        "elapsed": elapsed,
    }


def grade_commit(scenario: dict, result: dict) -> dict:
    """Grade a commit message against assertions."""
    msg = result["commit_message"]
    subject = msg.split("\n")[0] if msg else ""
    grades = {}

    for assertion_name, assertion_desc in scenario["assertions"].items():
        passed = False

        if assertion_name == "type_prefix":
            # Check for conventional commit prefix
            prefixes = re.findall(r"(\w+)(?:\([^)]*\))?:", assertion_desc)
            if not prefixes:
                prefixes = ["fix", "feat", "refactor", "ci", "chore", "build"]
            passed = bool(re.match(r"^(fix|feat|refactor|ci|chore|build|docs|style|perf|test)(\([^)]*\))?:", subject))

        elif assertion_name == "under_72_chars":
            passed = len(subject) <= 72

        elif assertion_name == "concise":
            passed = len(subject) <= 50

        elif assertion_name == "no_obvious_filler":
            filler = ["update code", "fix bug", "make changes", "update file", "modify"]
            passed = not any(f in subject.lower() for f in filler)

        elif assertion_name == "action_verb":
            verbs = ["add", "implement", "create", "introduce", "enable", "support"]
            passed = any(v in subject.lower() for v in verbs)

        elif assertion_name.startswith("mentions_"):
            # Content-specific checks
            full_msg = msg.lower()
            if "bug" in assertion_name:
                passed = any(w in full_msg for w in ["off-by-one", "paginate", "pagination", "slice", "page_size"])
            elif "endpoint" in assertion_name:
                passed = any(w in full_msg for w in ["settings", "endpoint", "route", "user"])
            elif "rename" in assertion_name:
                passed = any(w in full_msg for w in ["rename", "check_auth", "validate_token"])
            elif "node" in assertion_name:
                passed = any(w in full_msg for w in ["node", "22", "matrix"])

        grades[assertion_name] = {
            "description": assertion_desc,
            "passed": passed,
        }

    return grades


def main():
    parser = argparse.ArgumentParser(description="Quality eval for committing-changes")
    parser.add_argument("--case", help="Run specific scenario by name")
    parser.add_argument("--timeout", type=int, default=120, help="Timeout per scenario")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    scenarios = SCENARIOS
    if args.case:
        scenarios = [s for s in scenarios if s["name"] == args.case]
        if not scenarios:
            print(f"No scenario named '{args.case}'", file=sys.stderr)
            sys.exit(1)

    with tempfile.TemporaryDirectory(prefix="commit-eval-") as tmpdir:
        all_results = []

        for scenario in scenarios:
            if args.verbose:
                print(f"\n{'='*60}", file=sys.stderr)
                print(f"Scenario: {scenario['name']} — {scenario['description']}", file=sys.stderr)
                print(f"{'='*60}", file=sys.stderr)

            repo_dir = create_test_repo(scenario, tmpdir)
            result = run_commit_eval(scenario, repo_dir, args.timeout)

            if args.verbose:
                print(f"  Committed: {result['committed']}", file=sys.stderr)
                print(f"  Message: {result['commit_message'][:100]}", file=sys.stderr)
                print(f"  Time: {result['elapsed']}s", file=sys.stderr)

            grades = {}
            if result["committed"]:
                grades = grade_commit(scenario, result)
                if args.verbose:
                    for name, grade in grades.items():
                        status = "PASS" if grade["passed"] else "FAIL"
                        print(f"  [{status}] {name}: {grade['description']}", file=sys.stderr)
            else:
                if args.verbose:
                    print("  SKIP — no commit was created", file=sys.stderr)

            all_results.append({
                "scenario": scenario["name"],
                "committed": result["committed"],
                "commit_message": result["commit_message"],
                "grades": grades,
                "elapsed": result["elapsed"],
            })

        # Summary
        total_assertions = 0
        passed_assertions = 0
        committed_count = 0
        for r in all_results:
            if r["committed"]:
                committed_count += 1
            for g in r["grades"].values():
                total_assertions += 1
                if g["passed"]:
                    passed_assertions += 1

        if args.verbose:
            print(f"\n{'='*60}", file=sys.stderr)
            print(f"Summary: {committed_count}/{len(all_results)} scenarios committed", file=sys.stderr)
            print(f"Assertions: {passed_assertions}/{total_assertions} passed", file=sys.stderr)

        output = {
            "summary": {
                "scenarios": len(all_results),
                "committed": committed_count,
                "assertions_passed": passed_assertions,
                "assertions_total": total_assertions,
            },
            "results": all_results,
        }
        print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
