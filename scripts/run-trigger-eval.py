#!/usr/bin/env python3
"""Run trigger evaluation for a skill description.

Fixed version that creates proper SKILL.md files in .claude/skills/
instead of command files in .claude/commands/ (which don't auto-trigger).
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
from contextlib import contextmanager
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

    Detects triggering by looking for Skill tool calls matching the skill name.

    This function must NOT touch SKILL.md. The description swap happens once in
    the parent (see `swapped_description`) before any worker starts. It used to
    happen here, per worker, and that was a data-loss bug: `write_text` truncates
    before writing, so with N workers sharing one file a worker could read the
    empty window mid-write, store it as its `original_content`, and "restore"
    zero bytes at the end. It emptied skills/committing-changes/SKILL.md on
    2026-08-10.
    """
    try:
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
        pass


@contextmanager
def swapped_description(skill_file: Path, description: str):
    """Swap the frontmatter description for the duration of the block, once.

    Done in the parent process before any worker spawns, so the file is written
    exactly twice per run (swap, restore) regardless of worker count. Restores on
    any exit path, including KeyboardInterrupt and SIGTERM.
    """
    original = skill_file.read_text()

    lines = original.splitlines()
    new_lines = []
    in_frontmatter = False
    replaced = False
    for line in lines:
        if line.strip() == "---":
            in_frontmatter = not in_frontmatter
            new_lines.append(line)
            continue
        if in_frontmatter and line.startswith("description:") and not replaced:
            new_lines.append(f"description: {description}")
            replaced = True
        else:
            new_lines.append(line)
    # splitlines() drops the trailing newline; put it back so the swapped file
    # differs from the original in the description line and nothing else.
    trailing = "\n" if original.endswith("\n") else ""
    swapped = "\n".join(new_lines) + trailing

    def restore(*_):
        if skill_file.read_text() != original:
            skill_file.write_text(original)

    previous = {sig: signal.signal(sig, restore) for sig in (signal.SIGINT, signal.SIGTERM)}
    try:
        if swapped != original:
            skill_file.write_text(swapped)
        yield
    finally:
        restore()
        for sig, handler in previous.items():
            signal.signal(sig, handler)


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


def auto_trigger_disabled(skill_name: str, skill_path: Path) -> str | None:
    """Return a reason string when this skill cannot auto-trigger at all.

    Two independent causes, both of which produce a uniform 0.0 trigger rate that
    reads as a broken description rather than a disabled skill:

    1. `skillOverrides` set to user-invocable-only / name-only / off.
    2. The skill belongs to a plugin that is disabled in `enabledPlugins`.

    Guarding both is the difference between "your description needs work" and
    "this measurement was never capable of passing".
    """
    settings = Path.home() / ".claude" / "settings.json"
    if not settings.exists():
        return None
    try:
        cfg = json.loads(settings.read_text())
    except (json.JSONDecodeError, OSError):
        return None

    mode = cfg.get("skillOverrides", {}).get(skill_name)
    if mode in ("user-invocable-only", "name-only", "off"):
        return f'settings.json skillOverrides sets it to "{mode}"'

    # Walk up for a plugin manifest, then check whether that plugin is enabled.
    for parent in [skill_path.resolve(), *skill_path.resolve().parents]:
        manifest = parent / ".claude-plugin" / "plugin.json"
        if not manifest.exists():
            continue
        try:
            plugin_name = json.loads(manifest.read_text()).get("name")
        except (json.JSONDecodeError, OSError):
            return None
        if not plugin_name:
            return None
        for key, enabled in cfg.get("enabledPlugins", {}).items():
            if key.split("@")[0] == plugin_name and enabled is False:
                return f'it belongs to plugin "{key}", which is disabled in enabledPlugins'
        return None
    return None


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
    parser.add_argument(
        "--allow-disabled",
        action="store_true",
        help="run even when skillOverrides blocks auto-triggering (results will be all-zero)",
    )
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)
    name, original_description, _ = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root()

    blocked = auto_trigger_disabled(name, skill_path)
    if blocked and not args.allow_disabled:
        print(
            f"refusing to run: `{name}` cannot auto-trigger ({blocked}), so every\n"
            f"should_trigger=true case is guaranteed to fail and the result says\n"
            f"nothing about description quality.\n\n"
            f"Fix one of:\n"
            f"  - re-enable the skill (drop the skillOverrides entry, or\n"
            f"    `claude plugin enable <plugin>`) if it is meant to auto-trigger\n"
            f"  - set every should_trigger to false in {args.eval_set}\n"
            f"  - pass --allow-disabled to measure the description anyway",
            file=sys.stderr,
        )
        return 2

    if args.verbose:
        print(f"Evaluating: {description}", file=sys.stderr)

    results = []
    query_triggers: dict[str, list[bool]] = {}
    query_items: dict[str, dict] = {}

    # Swap once, in the parent, around the whole pool — never per worker.
    with swapped_description(skill_path / "SKILL.md", description):
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
    sys.exit(main() or 0)
