#!/usr/bin/env python3
"""Run trigger evaluation for a skill description.

Fixed version that creates proper SKILL.md files in .claude/skills/
instead of command files in .claude/commands/ (which don't auto-trigger).
"""

import argparse
import json
import os
import select
import subprocess
import sys
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def find_project_root() -> Path:
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
    skill_path: str | None = None,
) -> bool:
    """Run a single query and return whether the skill was triggered.

    Temporarily swaps the real skill's description in its SKILL.md, runs
    `claude -p`, then restores the original. Detects triggering by looking
    for Skill tool calls matching the skill name.
    """
    skill_dir = Path(skill_path) if skill_path else None
    skill_file = skill_dir / "SKILL.md" if skill_dir else None
    original_content = None

    try:
        # Swap description in real SKILL.md
        if skill_file and skill_file.exists():
            original_content = skill_file.read_text()
            # Replace description line in frontmatter
            lines = original_content.splitlines()
            new_lines = []
            in_frontmatter = False
            replaced = False
            for i, line in enumerate(lines):
                if line.strip() == "---":
                    if not in_frontmatter:
                        in_frontmatter = True
                        new_lines.append(line)
                        continue
                    else:
                        in_frontmatter = False
                        new_lines.append(line)
                        continue
                if in_frontmatter and line.startswith("description:") and not replaced:
                    new_lines.append(f"description: {skill_description}")
                    replaced = True
                else:
                    new_lines.append(line)
            skill_file.write_text("\n".join(new_lines))

        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
        ]
        if model:
            cmd.extend(["--model", model])

        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            cwd=project_root,
            env=env,
        )

        start_time = time.time()
        buffer = ""

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

            # Parse all lines looking for Skill tool calls
            for line in buffer.splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if event.get("type") == "assistant":
                    message = event.get("message", {})
                    for block in message.get("content", []):
                        if block.get("type") != "tool_use":
                            continue
                        tool_name = block.get("name", "")
                        tool_input = block.get("input", {})
                        if tool_name == "Skill" and skill_name in str(tool_input):
                            return True

                elif event.get("type") == "result":
                    return False

        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

        return False
    finally:
        # Restore original SKILL.md
        if skill_file and original_content is not None:
            skill_file.write_text(original_content)


def parse_skill_md(skill_path: Path) -> tuple[str, str, str]:
    text = (skill_path / "SKILL.md").read_text()
    if not text.startswith("---"):
        return skill_path.name, "", text
    end = text.index("---", 3)
    frontmatter = text[3:end]
    content = text[end + 3:].strip()
    name = skill_path.name
    description = ""
    for line in frontmatter.splitlines():
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip()
        elif line.startswith("description:"):
            description = line.split(":", 1)[1].strip()
    return name, description, content


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--skill-path", required=True)
    parser.add_argument("--description", default=None)
    parser.add_argument("--num-workers", type=int, default=5)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--runs-per-query", type=int, default=1)
    parser.add_argument("--trigger-threshold", type=float, default=0.5)
    parser.add_argument("--model", default=None)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)
    name, original_description, _ = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root()

    if args.verbose:
        print(f"Evaluating: {description}", file=sys.stderr)

    results = []
    with ProcessPoolExecutor(max_workers=args.num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(args.runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    name,
                    description,
                    args.timeout,
                    str(project_root),
                    args.model,
                    str(skill_path),
                )
                future_to_info[future] = (item, run_idx)

        query_triggers: dict[str, list[bool]] = {}
        query_items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            q = item["query"]
            query_items[q] = item
            if q not in query_triggers:
                query_triggers[q] = []
            try:
                query_triggers[q].append(future.result())
            except Exception as e:
                print(f"Warning: {e}", file=sys.stderr)
                query_triggers[q].append(False)

    for q, triggers in query_triggers.items():
        item = query_items[q]
        rate = sum(triggers) / len(triggers)
        should = item["should_trigger"]
        passed = rate >= args.trigger_threshold if should else rate < args.trigger_threshold
        results.append({
            "query": q,
            "should_trigger": should,
            "trigger_rate": rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": passed,
        })

    output = {
        "skill_name": name,
        "description": description,
        "results": results,
        "summary": {
            "total": len(results),
            "passed": sum(1 for r in results if r["pass"]),
            "failed": sum(1 for r in results if not r["pass"]),
        },
    }

    if args.verbose:
        s = output["summary"]
        print(f"Results: {s['passed']}/{s['total']} passed", file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else "FAIL"
            print(f"  [{status}] rate={r['triggers']}/{r['runs']} expected={r['should_trigger']}: {r['query'][:70]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
