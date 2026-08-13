#!/usr/bin/env python3
"""Evaluate behavioral rules from CLAUDE.md and rules files.

Tests whether Claude follows custom behavioral rules by sending queries
and checking response content for expected/forbidden patterns.

Usage:
    python evals/behavioral-eval.py --verbose
    python evals/behavioral-eval.py --eval-set evals/behavioral-eval.json --runs 3
    python evals/behavioral-eval.py --category custom-tooling --verbose
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def run_single_query(
    query: str,
    timeout: int,
    cwd: str,
) -> dict:
    """Run a single query via claude -p and return the response text."""
    cmd = [
        "claude",
        "-p",
        query,
        "--output-format",
        "text",
    ]

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=cwd,
            env=env,
        )
        response = result.stdout.strip()
        elapsed = round(time.time() - start_time, 1)
        return {"response": response, "elapsed": elapsed, "error": None}
    except subprocess.TimeoutExpired:
        elapsed = round(time.time() - start_time, 1)
        return {"response": "", "elapsed": elapsed, "error": "timeout"}
    except Exception as e:
        elapsed = round(time.time() - start_time, 1)
        return {"response": "", "elapsed": elapsed, "error": str(e)}


def check_patterns(response: str, case: dict) -> dict:
    """Check response against expected/forbidden patterns."""
    matches = []
    violations = []

    for pattern in case.get("expect_patterns", []):
        regex = re.compile(pattern, re.IGNORECASE)
        if regex.search(response):
            matches.append(pattern)

    for pattern in case.get("forbid_patterns", []):
        regex = re.compile(pattern, re.IGNORECASE)
        if regex.search(response):
            violations.append(pattern)

    expect_count = len(case.get("expect_patterns", []))
    forbid_count = len(case.get("forbid_patterns", []))

    # Pass if all expected patterns found AND no forbidden patterns found
    expect_pass = len(matches) == expect_count if expect_count > 0 else True
    forbid_pass = len(violations) == 0 if forbid_count > 0 else True

    return {
        "expect_pass": expect_pass,
        "forbid_pass": forbid_pass,
        "passed": expect_pass and forbid_pass,
        "matched": matches,
        "expected": expect_count,
        "violations": violations,
    }


def run_eval(
    eval_set: list[dict],
    num_workers: int,
    timeout: int,
    runs_per_query: int,
    cwd: str,
    category: str | None = None,
) -> dict:
    """Run the full eval set and return results."""
    # Filter by category if specified
    if category:
        eval_set = [c for c in eval_set if c.get("category") == category]

    results = []

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for case in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    case["query"],
                    timeout,
                    cwd,
                )
                future_to_info[future] = (case, run_idx)

        # Aggregate by query
        query_responses: dict[str, list[dict]] = {}
        query_cases: dict[str, dict] = {}

        for future in as_completed(future_to_info):
            case, _ = future_to_info[future]
            query = case["query"]
            query_cases[query] = case
            if query not in query_responses:
                query_responses[query] = []
            try:
                result = future.result()
                query_responses[query].append(result)
            except Exception as e:
                print(f"Warning: query failed: {e}", file=sys.stderr)
                query_responses[query].append(
                    {"response": "", "elapsed": 0, "error": str(e)}
                )

    for query, responses in query_responses.items():
        case = query_cases[query]
        run_results = []
        for resp in responses:
            if resp["error"]:
                run_results.append(False)
                continue
            check = check_patterns(resp["response"], case)
            run_results.append(check["passed"])

        pass_rate = sum(run_results) / len(run_results) if run_results else 0
        did_pass = pass_rate >= 0.5

        # Use last response for detail reporting
        last_resp = responses[-1]
        last_check = (
            check_patterns(last_resp["response"], case)
            if not last_resp["error"]
            else {"matched": [], "expected": 0, "violations": [], "passed": False}
        )

        results.append(
            {
                "name": case.get("name", query[:50]),
                "category": case.get("category", "uncategorized"),
                "query": query,
                "pass_rate": pass_rate,
                "runs": len(run_results),
                "pass": did_pass,
                "matched_patterns": last_check["matched"],
                "expected_patterns": len(case.get("expect_patterns", [])),
                "violations": last_check["violations"],
                "response_preview": last_resp["response"][:200]
                if last_resp["response"]
                else "(empty)",
            }
        )

    passed = sum(1 for r in results if r["pass"])
    total = len(results)

    # Group by category
    categories = {}
    for r in results:
        cat = r["category"]
        if cat not in categories:
            categories[cat] = {"passed": 0, "total": 0}
        categories[cat]["total"] += 1
        if r["pass"]:
            categories[cat]["passed"] += 1

    return {
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": f"{passed}/{total}",
            "by_category": categories,
        },
    }


def main():
    parser = argparse.ArgumentParser(
        description="Evaluate behavioral rules from config"
    )
    parser.add_argument(
        "--eval-set",
        default=str(Path(__file__).parent / "behavioral-eval.json"),
        help="Path to eval set JSON",
    )
    parser.add_argument("--category", help="Only run cases in this category")
    parser.add_argument("--num-workers", type=int, default=5, help="Parallel workers")
    parser.add_argument("--timeout", type=int, default=45, help="Timeout per query")
    parser.add_argument("--runs", type=int, default=1, help="Runs per query")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument(
        "--cwd", default=os.getcwd(), help="Working directory for claude -p"
    )
    args = parser.parse_args()

    if not Path(args.eval_set).exists():
        print(f"No eval set found at {args.eval_set}", file=sys.stderr)
        sys.exit(1)

    eval_set = json.loads(Path(args.eval_set).read_text())

    if args.verbose:
        cat_filter = f" (category={args.category})" if args.category else ""
        print(
            f"Running {len(eval_set)} behavioral eval cases{cat_filter}",
            file=sys.stderr,
        )

    output = run_eval(
        eval_set=eval_set,
        num_workers=args.num_workers,
        timeout=args.timeout,
        runs_per_query=args.runs,
        cwd=args.cwd,
        category=args.category,
    )

    if args.verbose:
        summary = output["summary"]
        print(
            f"\nResults: {summary['passed']}/{summary['total']} passed",
            file=sys.stderr,
        )
        for cat, stats in summary["by_category"].items():
            print(f"  {cat}: {stats['passed']}/{stats['total']}", file=sys.stderr)
        print(file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else "FAIL"
            rate_str = f"{r['pass_rate']:.0%}"
            detail = ""
            if r["violations"]:
                detail = f" violations={r['violations']}"
            elif not r["pass"]:
                detail = f" matched={r['matched_patterns']}/{r['expected_patterns']}"
            print(
                f"  [{status}] {rate_str} {r['name']}{detail}",
                file=sys.stderr,
            )
            if not r["pass"] and args.verbose:
                print(
                    f"         response: {r['response_preview'][:120]}",
                    file=sys.stderr,
                )

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
