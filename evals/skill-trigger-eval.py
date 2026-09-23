#!/usr/bin/env python3
"""Evaluate skill triggering for already-installed skills.

Unlike scripts/run-trigger-eval.py (which creates temp skills), this tests whether Claude
invokes real installed skills via the Skill tool when given a query.

Usage:
    python evals/skill-trigger-eval.py --skill using-jj --verbose
    python evals/skill-trigger-eval.py --skill monitoring-ci --runs 3
    python evals/skill-trigger-eval.py --all --verbose
"""

import argparse
import json
import os
import select
import signal
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

# Tools that cannot change anything. A session may call these while deciding
# whether to load a skill; any other tool call ends the run before it executes.
READ_ONLY_TOOLS = {"Skill", "Read", "Grep", "Glob", "ToolSearch"}


def kill_session(process: subprocess.Popen) -> None:
    """SIGKILL the claude process and every child it spawned (Bash, hooks)."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass
    process.wait()


def run_single_query(
    query: str,
    target_skill: str,
    timeout: int,
    cwd: str,
) -> dict:
    """Run a query via claude -p and report which skills it invoked.

    Each session is stopped at its first tool call outside READ_ONLY_TOOLS, at
    content_block_start, before the tool's input exists, and as soon as any
    Skill call resolves. Without that cutoff every query ran to completion with
    the user's real permissions: on 2026-09-18 a sweep in ~/.claude pushed a
    branch to origin, squashed local commits, and was mid-way through
    `linear-cli create` queries when it was killed.
    """
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
        cwd=cwd,
        env=env,
        start_new_session=True,
    )
    assert process.stdout is not None  # stdout=PIPE

    skills_invoked: set[str] = set()
    got_output = False
    stopped_by = None
    exited = False
    start_time = time.time()
    buffer = ""
    pending_skill = False
    accumulated_json = ""

    try:
        while time.time() - start_time < timeout and stopped_by is None and not exited:
            if process.poll() is not None:
                remaining = process.stdout.read()
                if remaining:
                    buffer += remaining.decode("utf-8", errors="replace")
                exited = True
            else:
                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue
                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    exited = True
                buffer += chunk.decode("utf-8", errors="replace")

            while "\n" in buffer and stopped_by is None:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                etype = event.get("type")
                if etype == "stream_event":
                    got_output = True
                    se = event.get("event", {})
                    se_type = se.get("type", "")
                    if se_type == "content_block_start":
                        cb = se.get("content_block", {})
                        if cb.get("type") == "tool_use":
                            name = cb.get("name", "")
                            if name == "Skill":
                                pending_skill = True
                                accumulated_json = ""
                            elif name not in READ_ONLY_TOOLS:
                                # Input not streamed yet, so the tool cannot run.
                                stopped_by = name
                    elif se_type == "content_block_delta" and pending_skill:
                        delta = se.get("delta", {})
                        if delta.get("type") == "input_json_delta":
                            accumulated_json += delta.get("partial_json", "")
                    elif se_type == "content_block_stop" and pending_skill:
                        try:
                            skills_invoked.add(json.loads(accumulated_json).get("skill", ""))
                        except json.JSONDecodeError:
                            pass
                        pending_skill = False
                        stopped_by = "Skill"
                elif etype == "assistant":
                    got_output = True
                    for item in event.get("message", {}).get("content", []):
                        if item.get("type") == "tool_use" and item.get("name") == "Skill":
                            skills_invoked.add(item.get("input", {}).get("skill", ""))
                elif etype == "result":
                    got_output = True
                    stopped_by = "result"
    finally:
        kill_session(process)

    triggered = target_skill in skills_invoked
    elapsed = round(time.time() - start_time, 1)

    return {
        "triggered": triggered,
        "skills_invoked": list(skills_invoked),
        "stopped_by": stopped_by,
        "elapsed": elapsed,
        # No stream, assistant, or result event means the run never reached
        # the model (logged out, rate limited, crashed). Scoring it as "not
        # triggered" would silently pass every negative case.
        "error": None if got_output else "no model output",
    }


def run_eval(
    eval_set: list[dict],
    target_skill: str,
    num_workers: int,
    timeout: int,
    runs_per_query: int,
    cwd: str,
) -> dict:
    """Run the full eval set and return results."""
    results = []

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    target_skill,
                    timeout,
                    cwd,
                )
                future_to_info[future] = (item, run_idx)

        # Aggregate by query
        query_triggers: dict[str, list[bool]] = {}
        query_errors: dict[str, int] = {}
        query_stops: dict[str, list[str]] = {}
        query_skills: dict[str, list[list[str]]] = {}
        query_items: dict[str, dict] = {}

        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            query = item["query"]
            query_items[query] = item
            if query not in query_triggers:
                query_triggers[query] = []
                query_errors[query] = 0
                query_stops[query] = []
                query_skills[query] = []
            try:
                result = future.result()
                if result.get("error"):
                    query_errors[query] += 1
                    continue
                query_triggers[query].append(result["triggered"])
                query_stops[query].append(result.get("stopped_by") or "timeout")
                query_skills[query].append(result["skills_invoked"])
            except Exception as e:
                print(f"Warning: query failed: {e}", file=sys.stderr)
                query_errors[query] += 1

    for query, triggers in query_triggers.items():
        item = query_items[query]
        if not triggers:
            results.append({
                "query": query,
                "should_trigger": item["should_trigger"],
                "trigger_rate": None,
                "triggers": 0,
                "runs": 0,
                "pass": False,
                "error": True,
                "skills_seen": [],
            })
            continue
        trigger_rate = sum(triggers) / len(triggers)
        should_trigger = item["should_trigger"]
        threshold = 0.5
        if should_trigger:
            did_pass = trigger_rate >= threshold
        else:
            did_pass = trigger_rate < threshold

        results.append({
            "query": query,
            "should_trigger": should_trigger,
            "trigger_rate": trigger_rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": did_pass,
            "skills_seen": query_skills[query],
            "stopped_by": query_stops[query],
        })

    passed = sum(1 for r in results if r["pass"])
    errors = sum(1 for r in results if r.get("error"))
    total = len(results)

    return {
        "skill_name": target_skill,
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed - errors,
            "errors": errors,
            "positive_rate": f"{sum(1 for r in results if r['should_trigger'] and r['pass'])}/{sum(1 for r in results if r['should_trigger'])}",
            "negative_rate": f"{sum(1 for r in results if not r['should_trigger'] and r['pass'])}/{sum(1 for r in results if not r['should_trigger'])}",
        },
    }


def frontmatter_blocks_trigger(skill_file: Path) -> str | None:
    """Return a reason when SKILL.md frontmatter keeps the model from auto-invoking it."""
    try:
        text = skill_file.read_text()
    except OSError:
        return None
    if not text.startswith("---"):
        return None
    for line in text[3:text.find("---", 3)].splitlines():
        key, _, value = line.partition(":")
        if key == "disable-model-invocation" and value.strip() == "true":
            return "its frontmatter sets disable-model-invocation: true"
        if key == "paths":
            return "its frontmatter sets paths:, so it only loads when a matching file is touched"
    return None


def main():
    parser = argparse.ArgumentParser(description="Evaluate skill triggering for installed skills")
    parser.add_argument("--skill", help="Skill name to evaluate")
    parser.add_argument("--eval-set", help="Path to eval set JSON (default: skills/<name>/evals/trigger-eval.json)")
    parser.add_argument("--all", action="store_true", help="Run all skills that have eval sets")
    parser.add_argument("--num-workers", type=int, default=5, help="Parallel workers")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per query")
    parser.add_argument("--runs", type=int, default=1, help="Runs per query")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--cwd", default=os.getcwd(), help="Working directory for claude -p")
    parser.add_argument("--summary", action="store_true", help="Print a summary table (useful with --all)")
    args = parser.parse_args()

    repo = Path(__file__).parent.parent
    skill_dirs: dict[str, Path] = {}
    for root in (repo / "skills", repo / ".claude" / "skills"):
        if root.is_dir():
            for d in sorted(root.iterdir()):
                if (d / "evals" / "trigger-eval.json").exists():
                    skill_dirs.setdefault(d.name, d)

    try:
        overrides = json.loads((Path.home() / ".claude" / "settings.json").read_text()).get("skillOverrides", {})
    except (OSError, json.JSONDecodeError):
        overrides = {}

    if args.all:
        skill_names = list(skill_dirs)
    elif args.skill:
        skill_names = [args.skill]
    else:
        parser.error("Specify --skill or --all")
        return

    all_outputs = []

    for skill_name in skill_names:
        mode = overrides.get(skill_name)
        if mode in ("user-invocable-only", "name-only", "off"):
            print(f"Skipping {skill_name}: skillOverrides sets it to \"{mode}\", so it cannot auto-trigger", file=sys.stderr)
            continue
        default_dir = skill_dirs.get(skill_name, repo / "skills" / skill_name)
        blocked = frontmatter_blocks_trigger(default_dir / "SKILL.md")
        if blocked:
            print(f"Skipping {skill_name}: {blocked}, so it cannot auto-trigger", file=sys.stderr)
            continue
        eval_path = args.eval_set or str(default_dir / "evals" / "trigger-eval.json")
        if not Path(eval_path).exists():
            print(f"No eval set found at {eval_path}", file=sys.stderr)
            continue

        eval_set = json.loads(Path(eval_path).read_text())
        if isinstance(eval_set, dict):
            eval_set = eval_set.get("cases", [])

        if args.verbose:
            print(f"\n{'='*60}", file=sys.stderr)
            print(f"Evaluating: {skill_name} ({len(eval_set)} queries)", file=sys.stderr)
            print(f"{'='*60}", file=sys.stderr)

        output = run_eval(
            eval_set=eval_set,
            target_skill=skill_name,
            num_workers=args.num_workers,
            timeout=args.timeout,
            runs_per_query=args.runs,
            cwd=args.cwd,
        )

        all_outputs.append(output)
        if output["summary"]["total"] and output["summary"]["errors"] == output["summary"]["total"]:
            print(f"\nAborting: every {skill_name} query returned no model output. "
                  f"Check `claude -p ok` (auth, rate limit) before rerunning.", file=sys.stderr)
            break

        if args.verbose:
            summary = output["summary"]
            print(f"\nResults: {summary['passed']}/{summary['total']} passed "
                  f"(positive: {summary['positive_rate']}, negative: {summary['negative_rate']})",
                  file=sys.stderr)
            for r in output["results"]:
                status = "ERROR" if r.get("error") else ("PASS" if r["pass"] else "FAIL")
                rate_str = f"{r['triggers']}/{r['runs']}"
                skills = r.get("skills_seen", [[]])
                skills_flat = set()
                for s in skills:
                    skills_flat.update(s)
                skills_str = f" skills={skills_flat}" if skills_flat else ""
                stop_str = f" stopped_by={r.get('stopped_by')}" if status == "FAIL" else ""
                print(f"  [{status}] rate={rate_str} expected={r['should_trigger']}: "
                      f"{r['query'][:60]}{skills_str}{stop_str}", file=sys.stderr)

        if not args.summary:
            print(json.dumps(output, indent=2))

    if args.summary and all_outputs:
        total_passed = 0
        total_cases = 0
        rows = []
        for o in all_outputs:
            s = o["summary"]
            total_passed += s["passed"]
            total_cases += s["total"]
            pct = round(100 * s["passed"] / s["total"]) if s["total"] else 0
            rows.append((o["skill_name"], s["passed"], s["total"], pct, s["positive_rate"], s["negative_rate"]))

        name_w = max(len(r[0]) for r in rows)
        print(f"\n{'Skill':<{name_w}}  Pass  Total   %  Pos       Neg", file=sys.stderr)
        print(f"{'-' * name_w}  ----  -----  ---  --------  --------", file=sys.stderr)
        for name, passed, total, pct, pos, neg in rows:
            marker = " " if pct == 100 else "*"
            print(f"{name:<{name_w}}  {passed:>4}  {total:>5}  {pct:>3}{marker} {pos:>9}  {neg:>8}", file=sys.stderr)

        overall_pct = round(100 * total_passed / total_cases) if total_cases else 0
        print(f"\nOverall: {total_passed}/{total_cases} ({overall_pct}%)", file=sys.stderr)

        print(json.dumps({"skills": all_outputs, "overall": {"passed": total_passed, "total": total_cases, "percent": overall_pct}}, indent=2))


if __name__ == "__main__":
    main()
